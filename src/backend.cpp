#include "backend.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QSslCertificate>
#include <QSslConfiguration>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

Backend::Backend(QObject* parent) : QObject(parent), rng_(std::random_device{}()) {
    swType_ = RuntimeConfig::softwareType();
    targetTemp_ = 5.0;
    targetTemp2_ = 5.0;

    mqttTimer_ = new QTimer(this);
    mqttTimer_->setInterval(mqtt_push_time);
    connect(mqttTimer_, &QTimer::timeout, this, &Backend::onMqttTimerTick);
    mqttTimer_->start();

    initLogs();
}

// =========== Setters ===========

void Backend::setSoftwareType(int type) {
    if (swType_ == type) return;
    swType_ = type;
    RuntimeConfig::setSoftwareType(type);
    emit softwareTypeChanged();
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

    QDateTime now = QDateTime::currentDateTime();
    // formát: "16:00 03.11.25 - Internal temp 3.4°C"
    QString line;
    if (swType_ == 3) {
        line = QStringLiteral("%1 - Internal temp %2%3C")
                   .arg(now.toString("HH:mm dd.MM.yy"), QString::number(v1, 'f', 1), QString::fromUtf8("°"));
    } else {
        line = QStringLiteral("%1 - Temp1 %2%3C ; Temp2 %4%3C")
                   .arg(now.toString("HH:mm dd.MM."), QString::number(v1, 'f', 1), QString::fromUtf8("°"), QString::number(v2, 'f', 1));
    }
    appendLogLine(line);
    appendAllTempsSnapshot();
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

void Backend::updateMqttConnected(bool ok) {
    if (mqttConnected_ == ok) return;

    mqttConnected_ = ok;
    emit mqttConnectedChanged();
}

void Backend::updateCoolingState(bool coolingActive, bool defrostActive, bool compressorOn) {
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
}

void Backend::updateCoolingState2(bool coolingActive, bool defrostActive, bool compressorOn) {
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
}

//
// ============= Sender MQTT =============

void Backend::sendMessage(const QString&) {
    const QByteArray payload = TelemetryBuilder::buildPayload(serialNumber(), value1_, value2_, value3_, value4_, value5_, value6_,
                                                              humidity_, targetTemp_, targetTemp2_, swType_);
    emit publishMqtt(payload);
}

void Backend::onMqttTimerTick() { sendMessage(QString()); }

//
// Logy budou v logManager.hpp/cpp v další verzi
//
// --- Logování teplot do souborů + bufferu ----------------------------------

void Backend::initLogs() {
    // Základní adresář pro logy je adresář aplikace + "/logs".
    QString basePath = QCoreApplication::applicationDirPath() + QStringLiteral("/..");

    QDir dir(basePath);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }

    if (!dir.cd(QStringLiteral("logs"))) {
        dir.mkdir(QStringLiteral("logs"));
        dir.cd(QStringLiteral("logs"));
    }

    logsDirPath_ = dir.absolutePath();

    const QString pattern = QStringLiteral("temperature_log_*.txt");
    const QString prefix = QStringLiteral("temperature_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);

    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    if (!indexToFile.isEmpty()) {
        // smaž staré logy, pokud jich je víc než limit
        while (indexToFile.size() > kMaxLogFiles) {
            const int firstKey = indexToFile.firstKey();
            const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
            QFile::remove(oldFile);
            indexToFile.remove(firstKey);
        }

        currentLogIndex_ = indexToFile.lastKey();
        currentLogFilePath_ = dir.absoluteFilePath(indexToFile.last());
        historyLog_ = loadLastLines(currentLogFilePath_, kMaxHistoryLines);
        emit historyLogChanged();
    } else {
        // žádný log ještě není – začneme od 1
        currentLogIndex_ = 1;
        const QString fileName = QStringLiteral("temperature_log_%1.txt").arg(currentLogIndex_, 3, 10, QChar('0'));
        currentLogFilePath_ = dir.absoluteFilePath(fileName);
        historyLog_.clear();
        emit historyLogChanged();
    }
    initTempsLogs();
}

void Backend::initTempsLogs() {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("alltemps_log_*.txt");
    const QString prefix = QStringLiteral("alltemps_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);
    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    if (!indexToFile.isEmpty()) {
        currentTempsLogIndex_ = indexToFile.lastKey();
        currentTempsLogFilePath_ = dir.absoluteFilePath(indexToFile.last());
    } else {
        currentTempsLogIndex_ = 1;
        const QString fileName = QStringLiteral("alltemps_log_%1.txt").arg(currentTempsLogIndex_, 3, 10, QChar('0'));
        currentTempsLogFilePath_ = dir.absoluteFilePath(fileName);
    }

    cleanupOldTempsLogFiles();
}

void Backend::appendTempsLogLine(const QString& line) {
    if (logsDirPath_.isEmpty()) {
        initLogs();
    }
    if (currentTempsLogFilePath_.isEmpty()) return;

    QFile file(currentTempsLogFilePath_);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << line << QLatin1Char('\n');
    }

    rotateTempsLogFileIfNeeded();
}

void Backend::rotateTempsLogFileIfNeeded() {
    if (currentTempsLogFilePath_.isEmpty()) return;

    QFileInfo info(currentTempsLogFilePath_);
    if (!info.exists()) return;

    if (info.size() < kMaxLogFileSizeBytes) return;

    QDir dir(logsDirPath_);
    ++currentTempsLogIndex_;

    const QString fileName = QStringLiteral("alltemps_log_%1.txt").arg(currentTempsLogIndex_, 3, 10, QChar('0'));
    currentTempsLogFilePath_ = dir.absoluteFilePath(fileName);

    cleanupOldTempsLogFiles();
}

void Backend::cleanupOldTempsLogFiles() {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("alltemps_log_*.txt");
    const QString prefix = QStringLiteral("alltemps_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);
    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    while (indexToFile.size() > kMaxLogFiles) {
        const int firstKey = indexToFile.firstKey();
        const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
        QFile::remove(oldFile);
        indexToFile.remove(firstKey);
    }
}

void Backend::appendAllTempsSnapshot() {
    const QDateTime now = QDateTime::currentDateTime();

    QString line;
    if (swType_ == 22) {
        line = QStringLiteral(
                   "%1 - target1: %2, target2: %3, vana-t1: %4, vana-t2: %5, vypar1: %6, vypar2: %7, kondenz: %8, nasavani: %9, hum: %10")
                   .arg(now.toString(QStringLiteral("HH:mm dd.MM.yy")), QString::number(targetTemp_, 'f', 1),
                        QString::number(targetTemp2_, 'f', 1), QString::number(value1_, 'f', 1), QString::number(value2_, 'f', 1),
                        QString::number(value3_, 'f', 1), QString::number(value4_, 'f', 1), QString::number(value5_, 'f', 1),
                        QString::number(value6_, 'f', 1), QString::number(humidity_, 'f', 1));
    } else {
        line = QStringLiteral("%1 - target: %2, vana-t1: %3, vypar: %4, kondenz: %5, nasavani: %6, hum: %7")
                   .arg(now.toString(QStringLiteral("HH:mm dd.MM.yy")), QString::number(targetTemp_, 'f', 1),
                        QString::number(value1_, 'f', 1), QString::number(value3_, 'f', 1), QString::number(value5_, 'f', 1),
                        QString::number(value6_, 'f', 1), QString::number(humidity_, 'f', 1));
    }
    appendTempsLogLine(line);
}

QStringList Backend::loadLastLines(const QString& filePath, int maxLines) const {
    QStringList result;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return result;

    QTextStream in(&file);
    in.setCodec("UTF-8");
    const QString content = in.readAll();
    QStringList lines = content.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    if (lines.size() <= maxLines) {
        for (QString& l : lines) result.append(l.trimmed());
    } else {
        const int start = lines.size() - maxLines;
        for (int i = start; i < lines.size(); ++i) {
            result.append(lines.at(i).trimmed());
        }
    }

    return result;
}

void Backend::appendLogLine(const QString& line) {
    if (logsDirPath_.isEmpty()) {
        initLogs();
    }

    historyLog_.append(line);
    while (historyLog_.size() > kMaxHistoryLines) {
        historyLog_.removeFirst();
    }
    emit historyLogChanged();

    if (currentLogFilePath_.isEmpty()) return;

    QFile file(currentLogFilePath_);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << line << QLatin1Char('\n');
    }

    rotateLogFileIfNeeded();
}

void Backend::rotateLogFileIfNeeded() {
    if (currentLogFilePath_.isEmpty()) return;

    QFileInfo info(currentLogFilePath_);
    if (!info.exists()) return;

    if (info.size() < kMaxLogFileSizeBytes) return;

    QDir dir(logsDirPath_);
    ++currentLogIndex_;

    const QString fileName = QStringLiteral("temperature_log_%1.txt").arg(currentLogIndex_, 3, 10, QChar('0'));
    currentLogFilePath_ = dir.absoluteFilePath(fileName);

    cleanupOldLogFiles();
}

void Backend::cleanupOldLogFiles() {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("temperature_log_*.txt");
    const QString prefix = QStringLiteral("temperature_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);
    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    while (indexToFile.size() > kMaxLogFiles) {
        const int firstKey = indexToFile.firstKey();
        const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
        QFile::remove(oldFile);
        indexToFile.remove(firstKey);
    }
}