#include "backend.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QMap>
#include <QProcess>
#include <QSet>
#include <QSslCertificate>
#include <QSslConfiguration>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>
#include <QVariantMap>
#include <algorithm>

namespace {

QStringList splitBySep(const QString& line, QChar sep) {
    QStringList out;
    QString cur;
    bool esc = false;
    for (const QChar c : line) {
        if (esc) {
            cur += c;
            esc = false;
            continue;
        }
        if (c == '\\') {
            esc = true;
            continue;
        }
        if (c == sep) {
            out << cur;
            cur.clear();
            continue;
        }
        cur += c;
    }
    out << cur;
    return out;
}

bool runNmcli(const QStringList& args, QString* outStd, QString* outErr, int timeoutMs = 4000) {
    QProcess p;
    p.start(QStringLiteral("nmcli"), args);
    if (!p.waitForFinished(timeoutMs)) {
        p.terminate();
        if (!p.waitForFinished(1500)) {
            p.kill();
            p.waitForFinished(1500);
        }
        if (outErr) *outErr = QStringLiteral("nmcli timeout");
        if (outStd) outStd->clear();
        return false;
    }
    if (outStd) *outStd = QString::fromUtf8(p.readAllStandardOutput());
    if (outErr) *outErr = QString::fromUtf8(p.readAllStandardError());
    return p.exitStatus() == QProcess::NormalExit && p.exitCode() == 0;
}

bool hasConnectedWifi(QString* activeSsid = nullptr) {
    if (activeSsid) activeSsid->clear();

    QString out;
    QString err;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("DEVICE,TYPE,STATE,CONNECTION"),
                   QStringLiteral("device"), QStringLiteral("status")},
                  &out, &err, 1200)) {
        return false;
    }

    const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 3) continue;
        const QString type = p[1].trimmed();
        const QString state = p[2].trimmed();
        if (type != QStringLiteral("wifi")) continue;
        if (state == QStringLiteral("connected")) {
            if (activeSsid && p.size() >= 4) *activeSsid = p[3].trimmed();
            return true;
        }
    }
    return false;
}

struct NetworkLinkState {
    bool wifiConnected = false;
    bool ethernetConnected = false;
};

NetworkLinkState readNetworkLinkState() {
    NetworkLinkState state;

    QString out;
    QString err;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("TYPE,STATE"),
                   QStringLiteral("device"), QStringLiteral("status")},
                  &out, &err, 1200)) {
        return state;
    }

    const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 2) continue;

        const QString type = p[0].trimmed();
        const QString deviceState = p[1].trimmed();
        if (deviceState != QStringLiteral("connected")) continue;

        if (type == QStringLiteral("wifi") || type == QStringLiteral("802-11-wireless")) {
            state.wifiConnected = true;
        } else if (type == QStringLiteral("ethernet") || type == QStringLiteral("802-3-ethernet")) {
            state.ethernetConnected = true;
        }
    }

    return state;
}

QString bandFromChannel(const QString& chStr) {
    bool ok = false;
    const int ch = chStr.toInt(&ok);
    if (!ok) return QStringLiteral("-");
    if (ch >= 1 && ch <= 14) return QStringLiteral("2.4 GHz");
    if (ch >= 15 && ch <= 196) return QStringLiteral("5 GHz");
    return QStringLiteral("6 GHz");
}

QSet<QString> wifiConnectionUuidsForSsid(const QString& ssid) {
    QSet<QString> outSet;
    const QString target = ssid.trimmed();
    if (target.isEmpty()) return outSet;

    QString out;
    QString err;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"),
                   QStringLiteral("UUID,TYPE,802-11-wireless.ssid"), QStringLiteral("connection"), QStringLiteral("show")},
                  &out, &err, 1800)) {
        return outSet;
    }

    const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 3) continue;
        const QString uuid = p[0].trimmed();
        const QString type = p[1].trimmed();
        const QString connSsid = p[2].trimmed();
        if (uuid.isEmpty()) continue;
        if (type != QStringLiteral("wifi") && type != QStringLiteral("802-11-wireless")) continue;
        if (connSsid == target) outSet.insert(uuid);
    }
    return outSet;
}

bool isDigitsOnly(const QString& s) {
    if (s.isEmpty()) return false;
    for (const QChar c : s) {
        if (!c.isDigit()) return false;
    }
    return true;
}

bool connectionNameMatchesSsid(const QString& name, const QString& ssid) {
    const QString n = name.trimmed();
    const QString s = ssid.trimmed();
    if (n == s) return true;
    if (!n.startsWith(s + QStringLiteral(" "))) return false;
    return isDigitsOnly(n.mid(s.size() + 1));
}

void cleanupFailedWifiProfiles(const QString& ssid, const QSet<QString>& knownProfileUuids) {
    const QString target = ssid.trimmed();
    if (target.isEmpty()) return;

    QString out;
    QString err;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"),
                   QStringLiteral("UUID,NAME,TYPE,802-11-wireless.ssid"), QStringLiteral("connection"), QStringLiteral("show")},
                  &out, &err, 2200)) {
        return;
    }

    const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 4) continue;
        const QString uuid = p[0].trimmed();
        const QString name = p[1].trimmed();
        const QString type = p[2].trimmed();
        const QString connSsid = p[3].trimmed();
        if (uuid.isEmpty()) continue;
        if (type != QStringLiteral("wifi") && type != QStringLiteral("802-11-wireless")) continue;
        if (knownProfileUuids.contains(uuid)) continue;

        const bool sameSsid = (connSsid == target);
        const bool sameName = connectionNameMatchesSsid(name, target);
        if (!sameSsid && !sameName) continue;

        QString delOut;
        QString delErr;
        runNmcli({QStringLiteral("connection"), QStringLiteral("delete"), QStringLiteral("uuid"), uuid}, &delOut, &delErr, 4000);
    }
}

bool isWifiAuthFailure(const QString& stdOut, const QString& stdErr) {
    const QString text = (stdOut + QLatin1Char('\n') + stdErr).toLower();
    return text.contains(QStringLiteral("wrong password"))
        || text.contains(QStringLiteral("incorrect password"))
        || text.contains(QStringLiteral("bad password"))
        || text.contains(QStringLiteral("secrets were required"))
        || text.contains(QStringLiteral("802.1x supplicant failed"))
        || text.contains(QStringLiteral("authentication"))
        || text.contains(QStringLiteral("password is required"));
}

}  // namespace

Backend::Backend(QObject* parent) : QObject(parent), rng_(std::random_device{}()) {
    swType_ = RuntimeConfig::softwareType();
    appLanguage_ = RuntimeConfig::appLanguage();
    targetTemp_ = 3.0;
    targetTemp2_ = 3.0;
    // auto defrost schedule (from runtime config)
    autoDefrostEnabled_ = RuntimeConfig::autoDefrostEnabled();
    autoDefrostTime1Min_ = RuntimeConfig::autoDefrostTime1Min();
    autoDefrostTime2Min_ = RuntimeConfig::autoDefrostTime2Min();

    mqttTimer_ = new QTimer(this);
    mqttTimer_->setInterval(mqtt_push_time);
    connect(mqttTimer_, &QTimer::timeout, this, &Backend::onMqttTimerTick);
    mqttTimer_->start();

    wifiMonitorTimer_ = new QTimer(this);
    wifiMonitorTimer_->setInterval(12000);
    connect(wifiMonitorTimer_, &QTimer::timeout, this, &Backend::onWifiMonitorTick);
    wifiMonitorTimer_->start();
    refreshNetworkLinkState();

    initLogManager();
}

void Backend::initLogManager() {
    logManager_.init(QString());

    connect(&logManager_, &LogManager::tempsHistoryChanged, this, &Backend::historyLogChanged);

    logManager_.setTempsSnapshotProvider([this]() { return buildTempsSnapshotLine(); });

    logManager_.startTempsTimer(AppConfig::TEMPS_LOG_INTERVAL_MS);
    // hned po startu jeden řádek, aby bylo jasné, že log běží
    logManager_.appendTempsSnapshotNow();
}

// =========== Setters ===========

void Backend::setSoftwareType(int type) {
    if (swType_ == type) return;
    swType_ = type;
    RuntimeConfig::setSoftwareType(type);
    emit softwareTypeChanged();
}

void Backend::setAppLanguage(const QString& lang) {
    const QString normalized = lang.trimmed().toLower();
    if (normalized.isEmpty() || appLanguage_ == normalized) return;
    appLanguage_ = normalized;
    RuntimeConfig::setAppLanguage(appLanguage_);
    emit appLanguageChanged();
}

void Backend::setTargetTemp(double t) {
    if (qFuzzyCompare(targetTemp_, t)) return;
    targetTemp_ = t;
    emit targetTempChanged();
}

void Backend::setTargetTemp2(double t) {
    if (qFuzzyCompare(targetTemp2_, t)) return;
    targetTemp2_ = t;
    emit targetTemp2Changed();
}

void Backend::setErrorActive(bool active) {
    if (errorActive_ == active) return;
    errorActive_ = active;
    emit errorActiveChanged();
}

void Backend::setReclaimOrderNumber(const QString& number) {
    RuntimeConfig::setReclaimOrderNumber(number);
    emit reclaimInfoChanged();
}

void Backend::setReclaimEmail(const QString& email) {
    RuntimeConfig::setReclaimEmail(email);
    emit reclaimInfoChanged();
}

void Backend::setPower1On(bool on) {
    if (power1On_ == on) return;
    power1On_ = on;
    emit power1OnChanged();
    emit requestPower1(on);
}

void Backend::setPower2On(bool on) {
    if (power2On_ == on) return;
    power2On_ = on;
    emit power2OnChanged();
    emit requestPower2(on);
}

void Backend::setBath1Enabled(bool en) {
    if (bath1Enabled_ == en) return;
    bath1Enabled_ = en;
    emit bath1EnabledChanged();
    emit requestBath1Enabled(en);
}

void Backend::setBath2Enabled(bool en) {
    if (bath2Enabled_ == en) return;
    bath2Enabled_ = en;
    emit bath2EnabledChanged();
    emit requestBath2Enabled(en);
}

// =========== Auto defrost schedule (settings) ===========
void Backend::setAutoDefrostEnabled(bool en) {
    if (autoDefrostEnabled_ == en) return;
    autoDefrostEnabled_ = en;
    RuntimeConfig::setAutoDefrostEnabled(en);
    emit autoDefrostEnabledChanged();
    emit requestAutoDefrostEnabled(en);
}

void Backend::setAutoDefrostTime1Min(int minutes) {
    if (autoDefrostTime1Min_ == minutes) return;
    autoDefrostTime1Min_ = minutes;
    RuntimeConfig::setAutoDefrostTime1Min(minutes);
    emit autoDefrostTimeChanged();
    emit requestAutoDefrostTimes(autoDefrostTime1Min_, autoDefrostTime2Min_);
}

void Backend::setAutoDefrostTime2Min(int minutes) {
    if (autoDefrostTime2Min_ == minutes) return;
    autoDefrostTime2Min_ = minutes;
    RuntimeConfig::setAutoDefrostTime2Min(minutes);
    emit autoDefrostTimeChanged();
    emit requestAutoDefrostTimes(autoDefrostTime1Min_, autoDefrostTime2Min_);
}

// =========== Sensor config setters ===========
void Backend::setSensor1Id(const QString& id) {
    RuntimeConfig::setSensor1Id(id);
    emit requestSetSensor1Id(id);
    emit sensorConfigChanged();
}
void Backend::setSensor2Id(const QString& id) {
    RuntimeConfig::setSensor2Id(id);
    emit requestSetSensor2Id(id);
    emit sensorConfigChanged();
}
void Backend::setSensor3Id(const QString& id) {
    RuntimeConfig::setSensor3Id(id);
    emit requestSetSensor3Id(id);
    emit sensorConfigChanged();
}
void Backend::setSensor4Id(const QString& id) {
    RuntimeConfig::setSensor4Id(id);
    emit requestSetSensor4Id(id);
    emit sensorConfigChanged();
}
void Backend::setSensor5Id(const QString& id) {
    RuntimeConfig::setSensor5Id(id);
    emit requestSetSensor5Id(id);
    emit sensorConfigChanged();
}
void Backend::setSensor6Id(const QString& id) {
    RuntimeConfig::setSensor6Id(id);
    emit requestSetSensor6Id(id);
    emit sensorConfigChanged();
}

// =========== Sensor offsets setters ===========
void Backend::setSensor1Offset(double off) {
    RuntimeConfig::setSensor1Offset(off);
    emit requestSetSensor1Offset(off);
    emit sensorConfigChanged();
}
void Backend::setSensor2Offset(double off) {
    RuntimeConfig::setSensor2Offset(off);
    emit requestSetSensor2Offset(off);
    emit sensorConfigChanged();
}
void Backend::setSensor3Offset(double off) {
    RuntimeConfig::setSensor3Offset(off);
    emit requestSetSensor3Offset(off);
    emit sensorConfigChanged();
}
void Backend::setSensor4Offset(double off) {
    RuntimeConfig::setSensor4Offset(off);
    emit requestSetSensor4Offset(off);
    emit sensorConfigChanged();
}
void Backend::setSensor5Offset(double off) {
    RuntimeConfig::setSensor5Offset(off);
    emit requestSetSensor5Offset(off);
    emit sensorConfigChanged();
}
void Backend::setSensor6Offset(double off) {
    RuntimeConfig::setSensor6Offset(off);
    emit requestSetSensor6Offset(off);
    emit sensorConfigChanged();
}

//
// =========== Forced setters ===========

void Backend::setForcedSensors(bool en) {
    if (forcedSensors_ == en) return;
    forcedSensors_ = en;

    if (forcedSensors_) {
        if (!std::isfinite(forcedT1_)) forcedT1_ = targetTemp_;
        if (!std::isfinite(forcedT3_)) forcedT3_ = -5.0;
        if (!std::isfinite(forcedT5_)) forcedT5_ = 20.0;

        if (swType_ == 22) {
            if (!std::isfinite(forcedT2_)) forcedT2_ = targetTemp2_;
            if (!std::isfinite(forcedT4_)) forcedT4_ = -5.0;
        }
        emit forcedTempsChanged();
    }
    emit forcedSensorsChanged();
    emit requestForcedEnabled(forcedSensors_);
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp1(double v) {
    if (qFuzzyCompare(forcedT1_, v)) return;
    forcedT1_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp2(double v) {
    if (qFuzzyCompare(forcedT2_, v)) return;
    forcedT2_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp3(double v) {
    if (qFuzzyCompare(forcedT3_, v)) return;
    forcedT3_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp4(double v) {
    if (qFuzzyCompare(forcedT4_, v)) return;
    forcedT4_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp5(double v) {
    if (qFuzzyCompare(forcedT5_, v)) return;
    forcedT5_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

//
// =========== Slots for worker threads ===========

void Backend::updateTempValue(double v1, double v2, double v3, double v4, double v5) {
    if (!qFuzzyCompare(value1_, v1)) {
        value1_ = v1;
        emit value1Changed();
    }
    if (!qFuzzyCompare(value2_, v2)) {
        value2_ = v2;
        emit value2Changed();
    }
    if (!qFuzzyCompare(value3_, v3)) {
        value3_ = v3;
        emit value3Changed();
    }
    if (!qFuzzyCompare(value4_, v4)) {
        value4_ = v4;
        emit value4Changed();
    }
    if (!qFuzzyCompare(value5_, v5)) {
        value5_ = v5;
        emit value5Changed();
    }
}

void Backend::updateIntakeValue(double v6, double hum) {
    if (!qFuzzyCompare(value6_, v6)) {
        value6_ = v6;
        emit value6Changed();
    }
    if (!qFuzzyCompare(humidity_, hum)) {
        humidity_ = hum;
        emit humidityChanged();
    }
}

void Backend::refreshVisibleOneWireIds() { emit requestRefreshVisibleOneWireIds(); }

void Backend::updateVisibleOneWireIds(const QStringList& ids) {
    if (ids == visibleOneWireIds_) return;
    visibleOneWireIds_ = ids;
    emit visibleOneWireIdsChanged();
}

void Backend::updateMqttConnected(bool ok) {
    if (mqttConnected_ == ok) return;

    mqttConnected_ = ok;
    emit mqttConnectedChanged();
}

void Backend::updateCoolingState(bool coolingActive, bool defrostActive, bool compressorOn, bool dripHoldActive) {
    if (coolingActive_ != coolingActive) {
        coolingActive_ = coolingActive;
        emit coolingActiveChanged();
    }
    if (defrostActive_ != defrostActive) {
        defrostActive_ = defrostActive;
        emit defrostActiveChanged();
    }
    if (compressorOn_ != compressorOn) {
        compressorOn_ = compressorOn;
        emit compressorOnChanged();
    }

    if (dripHoldActive_ != dripHoldActive) {
        dripHoldActive_ = dripHoldActive;
        emit dripHoldActiveChanged();
    }
}

void Backend::updateCoolingState2(bool coolingActive, bool defrostActive, bool compressorOn, bool dripHoldActive) {
    if (cooling2Active_ != coolingActive) {
        cooling2Active_ = coolingActive;
        emit cooling2ActiveChanged();
    }
    if (defrost2Active_ != defrostActive) {
        defrost2Active_ = defrostActive;
        emit defrost2ActiveChanged();
    }
    if (compressor2On_ != compressorOn) {
        compressor2On_ = compressorOn;
        emit compressor2OnChanged();
    }

    if (dripHold2Active_ != dripHoldActive) {
        dripHold2Active_ = dripHoldActive;
        emit dripHold2ActiveChanged();
    }
}

//
// ============= Sender MQTT =============

void Backend::sendMessage(const QString&) {
    const QByteArray payload =
        TelemetryBuilder::buildPayload(value1_, value2_, value3_, value4_, value5_, value6_, humidity_, targetTemp_, targetTemp2_, swType_);
    emit publishMqtt(payload);
}

void Backend::onMqttTimerTick() { sendMessage(QString()); }

//

void Backend::setWifiLastMessage(const QString& msg) {
    if (wifiLastMessage_ == msg) return;
    wifiLastMessage_ = msg;
    emit wifiLastMessageChanged();
}

void Backend::setWifiConnected(bool connected) {
    if (wifiConnected_ == connected) return;
    wifiConnected_ = connected;
    emit wifiConnectedChanged();
}

void Backend::setEthernetConnected(bool connected) {
    if (ethernetConnected_ == connected) return;
    ethernetConnected_ = connected;
    emit ethernetConnectedChanged();
}

void Backend::setWifiAuthFailure(bool failed) {
    if (wifiAuthFailure_ == failed) return;
    wifiAuthFailure_ = failed;
    emit wifiAuthFailureChanged();
}

void Backend::refreshNetworkLinkState() {
    const NetworkLinkState state = readNetworkLinkState();
    setWifiConnected(state.wifiConnected);
    setEthernetConnected(state.ethernetConnected);
}

QVariantList Backend::wifiScanNetworks(bool forceRescan) {
    QString savedOut;
    QString savedErr;
    QSet<QString> savedNames;
    if (runNmcli({QStringLiteral("-t"), QStringLiteral("-f"),
                  QStringLiteral("NAME,TYPE"), QStringLiteral("connection"), QStringLiteral("show")},
                 &savedOut, &savedErr, 1500)) {
        const QStringList lines = savedOut.split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            const QStringList parts = splitBySep(line, ':');
            if (parts.size() < 2) continue;
            const QString type = parts[1].trimmed();
            if (type == QStringLiteral("wifi") || type == QStringLiteral("802-11-wireless")) {
                savedNames.insert(parts[0].trimmed());
            }
        }
    }

    QString ipAddr;
    {
        QString devOut;
        QString devErr;
        if (runNmcli({QStringLiteral("-t"), QStringLiteral("-f"),
                      QStringLiteral("DEVICE,TYPE,STATE"), QStringLiteral("device"), QStringLiteral("status")},
                     &devOut, &devErr, 1500)) {
            const QStringList lines = devOut.split('\n', Qt::SkipEmptyParts);
            QString activeDev;
            for (const QString& line : lines) {
                const QStringList p = splitBySep(line, ':');
                if (p.size() < 3) continue;
                if (p[1].trimmed() == QStringLiteral("wifi") && p[2].trimmed() == QStringLiteral("connected")) {
                    activeDev = p[0].trimmed();
                    break;
                }
            }
            if (!activeDev.isEmpty()) {
                QString ipOut;
                QString ipErr;
                if (runNmcli({QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("IP4.ADDRESS"), QStringLiteral("device"),
                              QStringLiteral("show"), activeDev},
                             &ipOut, &ipErr, 1500)) {
                    const QStringList ipLines = ipOut.split('\n', Qt::SkipEmptyParts);
                    if (!ipLines.isEmpty()) {
                        const int pos = ipLines.first().indexOf(':');
                        if (pos >= 0) {
                            ipAddr = ipLines.first().mid(pos + 1).trimmed();
                            const int slash = ipAddr.indexOf('/');
                            if (slash > 0) ipAddr = ipAddr.left(slash);
                        }
                    }
                }
            }
        }
    }

    QString out;
    QString err;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"),
                   QStringLiteral("IN-USE,BSSID,SSID,SIGNAL,SECURITY,CHAN"), QStringLiteral("device"), QStringLiteral("wifi"),
                   QStringLiteral("list"), QStringLiteral("--rescan"), forceRescan ? QStringLiteral("yes") : QStringLiteral("no")},
                  &out, &err, forceRescan ? 5000 : 2000)) {
        setWifiLastMessage(QStringLiteral("Wi-Fi scan failed: %1").arg(err.trimmed()));
        return {};
    }

    QHash<QString, QVariantMap> bestBySsid;
    const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 6) continue;

        const QString inUse = p[0].trimmed();
        const QString bssid = p[1].trimmed();
        const QString ssid = p[2].trimmed();
        if (ssid.isEmpty()) continue;

        const QString rawSecurity = p[4].trimmed();
        const QString security = (rawSecurity.isEmpty() || rawSecurity == QStringLiteral("--")) ? QStringLiteral("Open") : rawSecurity;
        const QString band = bandFromChannel(p[5].trimmed());
        const bool connected = (inUse == QStringLiteral("*") || inUse.compare(QStringLiteral("yes"), Qt::CaseInsensitive) == 0);
        const bool enterprise = security.contains(QStringLiteral("802.1X"), Qt::CaseInsensitive)
                             || security.contains(QStringLiteral("WPA-EAP"), Qt::CaseInsensitive)
                             || security.contains(QStringLiteral("EAP"), Qt::CaseInsensitive);
        const bool requiresPassword = security.compare(QStringLiteral("Open"), Qt::CaseInsensitive) != 0;

        QVariantMap m;
        m.insert(QStringLiteral("ssid"), ssid);
        m.insert(QStringLiteral("bssid"), bssid);
        m.insert(QStringLiteral("connected"), connected);
        m.insert(QStringLiteral("saved"), savedNames.contains(ssid));
        m.insert(QStringLiteral("security"), security);
        m.insert(QStringLiteral("band"), band);
        m.insert(QStringLiteral("ipAddress"), connected ? ipAddr : QString());
        m.insert(QStringLiteral("requiresPassword"), requiresPassword);
        m.insert(QStringLiteral("requiresUsernamePassword"), enterprise);
        m.insert(QStringLiteral("signal"), 0);
        if (connected) m.insert(QStringLiteral("statusKey"), QStringLiteral("connected"));
        else if (enterprise) m.insert(QStringLiteral("statusKey"), QStringLiteral("enterprise"));
        else if (requiresPassword) m.insert(QStringLiteral("statusKey"), QStringLiteral("available"));
        else m.insert(QStringLiteral("statusKey"), QStringLiteral("open"));

        const bool hasExisting = bestBySsid.contains(ssid);
        if (!hasExisting) {
            bestBySsid.insert(ssid, m);
            continue;
        }

        const QVariantMap existing = bestBySsid.value(ssid);
        const bool existingConnected = existing.value(QStringLiteral("connected")).toBool();
        const bool existingSaved = existing.value(QStringLiteral("saved")).toBool();
        const bool saved = m.value(QStringLiteral("saved")).toBool();

        bool replace = false;
        if (connected && !existingConnected) replace = true;
        else if (connected == existingConnected && saved && !existingSaved) replace = true;

        if (replace) {
            bestBySsid.insert(ssid, m);
        }
    }

    QVector<QVariantMap> sorted = bestBySsid.values().toVector();
    std::sort(sorted.begin(), sorted.end(), [](const QVariantMap& a, const QVariantMap& b) {
        const bool ac = a.value(QStringLiteral("connected")).toBool();
        const bool bc = b.value(QStringLiteral("connected")).toBool();
        if (ac != bc) return ac > bc;
        const QString as = a.value(QStringLiteral("ssid")).toString();
        const QString bs = b.value(QStringLiteral("ssid")).toString();
        return as.localeAwareCompare(bs) < 0;
    });

    QVariantList result;
    bool connectedFound = false;
    for (const QVariantMap& m : sorted) {
        if (m.value(QStringLiteral("connected")).toBool()) connectedFound = true;
        result.push_back(m);
    }

    if (result.isEmpty()) setWifiLastMessage(QStringLiteral("No Wi-Fi networks found."));
    else setWifiLastMessage(QString());
    refreshNetworkLinkState();
    if (!wifiConnected_ && connectedFound) setWifiConnected(true);
    return result;
}

bool Backend::wifiDisconnect(const QString& ssid) {
    QString out;
    QString err;

    if (!ssid.trimmed().isEmpty()) {
        const bool ok = runNmcli({QStringLiteral("connection"), QStringLiteral("down"), ssid.trimmed()}, &out, &err, 10000);
        setWifiLastMessage(ok ? QStringLiteral("Disconnected: %1").arg(ssid.trimmed())
                              : QStringLiteral("Disconnect failed: %1").arg(err.trimmed()));
        if (ok) autoReconnectSuppressedUntil_ = QDateTime::currentDateTime().addSecs(45);
        if (ok) refreshNetworkLinkState();
        return ok;
    }

    QString activeOut;
    QString activeErr;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"),
                   QStringLiteral("NAME,TYPE"), QStringLiteral("connection"), QStringLiteral("show"), QStringLiteral("--active")},
                  &activeOut, &activeErr, 2000)) {
        setWifiLastMessage(QStringLiteral("Cannot read active connections: %1").arg(activeErr.trimmed()));
        return false;
    }

    bool any = false;
    bool allOk = true;
    const QStringList lines = activeOut.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : lines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 2) continue;
        const QString name = p[0].trimmed();
        const QString type = p[1].trimmed();
        if (name.isEmpty()) continue;
        if (type != QStringLiteral("wifi") && type != QStringLiteral("802-11-wireless")) continue;
        any = true;
        QString downOut;
        QString downErr;
        const bool ok = runNmcli({QStringLiteral("connection"), QStringLiteral("down"), name}, &downOut, &downErr, 10000);
        if (!ok) allOk = false;
    }

    if (!any) {
        setWifiLastMessage(QStringLiteral("No active Wi-Fi connection."));
        return true;
    }
    setWifiLastMessage(allOk ? QStringLiteral("Wi-Fi disconnected.") : QStringLiteral("Some Wi-Fi disconnects failed."));
    if (allOk) autoReconnectSuppressedUntil_ = QDateTime::currentDateTime().addSecs(45);
    if (allOk) refreshNetworkLinkState();
    return allOk;
}

bool Backend::wifiConnect(const QString& ssid, const QString& username, const QString& password, bool enterprise, const QString& bssid) {
    const QString s = ssid.trimmed();
    setWifiAuthFailure(false);
    if (s.isEmpty()) {
        setWifiLastMessage(QStringLiteral("SSID is empty."));
        return false;
    }
    const QSet<QString> knownProfileUuids = wifiConnectionUuidsForSsid(s);

    QString out;
    QString err;
    bool ok = false;

    if (username.trimmed().isEmpty() && password.isEmpty()) {
        ok = runNmcli({QStringLiteral("connection"), QStringLiteral("up"), s}, &out, &err, 12000);
        if (ok) {
            setWifiLastMessage(QStringLiteral("Connected to: %1").arg(s));
            refreshNetworkLinkState();
            return true;
        }
    }

    if (enterprise) {
        if (username.trimmed().isEmpty() || password.isEmpty()) {
            setWifiLastMessage(QStringLiteral("Username/password required for enterprise Wi-Fi."));
            return false;
        }

        QString tmpName = QStringLiteral("lnvg_eap_%1").arg(s);
        tmpName.replace('/', '_');
        tmpName.replace('\\', '_');
        tmpName.replace(' ', '_');

        QString dropOut;
        QString dropErr;
        runNmcli({QStringLiteral("connection"), QStringLiteral("delete"), tmpName}, &dropOut, &dropErr, 4000);

        ok = runNmcli({QStringLiteral("connection"), QStringLiteral("add"), QStringLiteral("type"), QStringLiteral("wifi"),
                       QStringLiteral("ifname"), QStringLiteral("*"), QStringLiteral("con-name"), tmpName, QStringLiteral("ssid"), s},
                      &out, &err, 12000);
        if (!ok) {
            runNmcli({QStringLiteral("connection"), QStringLiteral("delete"), tmpName}, &out, &err, 3000);
            setWifiLastMessage(QStringLiteral("Enterprise setup failed: %1").arg(err.trimmed()));
            return false;
        }

        ok = runNmcli({QStringLiteral("connection"), QStringLiteral("modify"), tmpName, QStringLiteral("wifi-sec.key-mgmt"),
                       QStringLiteral("wpa-eap"), QStringLiteral("802-1x.eap"), QStringLiteral("peap"),
                       QStringLiteral("802-1x.identity"), username.trimmed(), QStringLiteral("802-1x.password"), password,
                       QStringLiteral("802-1x.phase2-auth"), QStringLiteral("mschapv2")},
                      &out, &err, 12000);
        if (!ok) {
            runNmcli({QStringLiteral("connection"), QStringLiteral("delete"), tmpName}, &out, &err, 3000);
            setWifiLastMessage(QStringLiteral("Enterprise credentials failed: %1").arg(err.trimmed()));
            return false;
        }

        if (!bssid.trimmed().isEmpty()) {
            runNmcli({QStringLiteral("connection"), QStringLiteral("modify"), tmpName, QStringLiteral("wifi.bssid"), bssid.trimmed()},
                     &out, &err, 4000);
        }

        ok = runNmcli({QStringLiteral("connection"), QStringLiteral("up"), tmpName}, &out, &err, 12000);
        if (!ok) {
            runNmcli({QStringLiteral("connection"), QStringLiteral("delete"), tmpName}, &out, &err, 3000);
        }
    } else {
        QStringList args{QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("connect"), s};
        if (!bssid.trimmed().isEmpty()) {
            args << QStringLiteral("bssid") << bssid.trimmed();
        }
        if (!password.isEmpty()) {
            args << QStringLiteral("password") << password;
        }
        ok = runNmcli(args, &out, &err, 12000);
    }

    const bool authFailure = !ok && isWifiAuthFailure(out, err);
    setWifiAuthFailure(authFailure);
    setWifiLastMessage(ok ? QStringLiteral("Connected to: %1").arg(s)
                          : authFailure ? QStringLiteral("Wrong Wi-Fi password. Network was not saved.")
                                        : QStringLiteral("Connect failed: %1").arg(err.trimmed()));
    if (authFailure) wifiForget(s);
    else if (!ok) cleanupFailedWifiProfiles(s, knownProfileUuids);
    refreshNetworkLinkState();
    return ok;
}

bool Backend::wifiForget(const QString& ssid) {
    const QString s = ssid.trimmed();
    if (s.isEmpty()) {
        setWifiLastMessage(QStringLiteral("SSID is empty."));
        return false;
    }

    QString out;
    QString err;
    const bool ok = runNmcli({QStringLiteral("connection"), QStringLiteral("delete"), s}, &out, &err, 10000);
    setWifiLastMessage(ok ? QStringLiteral("Forgotten network: %1").arg(s)
                          : QStringLiteral("Forget failed: %1").arg(err.trimmed()));
    return ok;
}

void Backend::onWifiMonitorTick() {
    if (autoReconnectSuppressedUntil_.isValid() && QDateTime::currentDateTime() < autoReconnectSuppressedUntil_) return;

    refreshNetworkLinkState();
    if (ethernetConnected_) return;
    if (wifiConnected_) return;

    QString savedOut;
    QString savedErr;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("NAME,TYPE"), QStringLiteral("connection"),
                   QStringLiteral("show")},
                  &savedOut, &savedErr, 1200)) {
        return;
    }

    QSet<QString> savedWifi;
    const QStringList savedLines = savedOut.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : savedLines) {
        const QStringList p = splitBySep(line, ':');
        if (p.size() < 2) continue;
        const QString name = p[0].trimmed();
        const QString type = p[1].trimmed();
        if (name.isEmpty()) continue;
        if (type == QStringLiteral("wifi") || type == QStringLiteral("802-11-wireless")) savedWifi.insert(name);
    }
    if (savedWifi.isEmpty()) return;

    QString scanOut;
    QString scanErr;
    if (!runNmcli({QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("SSID"), QStringLiteral("device"),
                   QStringLiteral("wifi"), QStringLiteral("list"), QStringLiteral("--rescan"), QStringLiteral("no")},
                  &scanOut, &scanErr, 1500)) {
        return;
    }

    QStringList candidates;
    const QStringList scanLines = scanOut.split('\n', Qt::SkipEmptyParts);
    for (const QString& line : scanLines) {
        const QString ssid = splitBySep(line, ':').value(0).trimmed();
        if (ssid.isEmpty() || !savedWifi.contains(ssid)) continue;
        if (!candidates.contains(ssid)) candidates << ssid;
    }

    if (candidates.isEmpty()) return;

    for (const QString& ssid : candidates) {
        QString out;
        QString err;
        const bool ok = runNmcli({QStringLiteral("connection"), QStringLiteral("up"), ssid}, &out, &err, 5000);
        if (ok) {
            setWifiLastMessage(QStringLiteral("Auto reconnected: %1").arg(ssid));
            refreshNetworkLinkState();
            return;
        }
    }

    autoReconnectSuppressedUntil_ = QDateTime::currentDateTime().addSecs(12);
}

QString Backend::buildTempsSnapshotLine() const {
    const QDateTime now = QDateTime::currentDateTime();

    if (swType_ == 22) {
        return QStringLiteral(
                   "%1 - target1: %2, target2: %3, vana-t1: %4, vana-t2: %5, vypar1: %6, vypar2: %7, kondenz: %8, nasavani: %9, hum: %10")
            .arg(now.toString(QStringLiteral("HH:mm dd.MM.yy")), QString::number(targetTemp_, 'f', 1),
                 QString::number(targetTemp2_, 'f', 1), QString::number(value1_, 'f', 1), QString::number(value2_, 'f', 1),
                 QString::number(value3_, 'f', 1), QString::number(value4_, 'f', 1), QString::number(value5_, 'f', 1),
                 QString::number(value6_, 'f', 1), QString::number(humidity_, 'f', 1));
    }

    return QStringLiteral("%1 - target: %2, vana-t1: %3, vypar: %4, kondenz: %5, nasavani: %6, hum: %7")
        .arg(now.toString(QStringLiteral("HH:mm dd.MM.yy")), QString::number(targetTemp_, 'f', 1), QString::number(value1_, 'f', 1),
             QString::number(value3_, 'f', 1), QString::number(value5_, 'f', 1), QString::number(value6_, 'f', 1),
             QString::number(humidity_, 'f', 1));
}
