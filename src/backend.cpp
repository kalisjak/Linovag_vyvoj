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
    // auto defrost schedule (from runtime config)
    autoDefrostEnabled_ = RuntimeConfig::autoDefrostEnabled();
    autoDefrostTime1Min_ = RuntimeConfig::autoDefrostTime1Min();
    autoDefrostTime2Min_ = RuntimeConfig::autoDefrostTime2Min();

    mqttTimer_ = new QTimer(this);
    mqttTimer_->setInterval(mqtt_push_time);
    connect(mqttTimer_, &QTimer::timeout, this, &Backend::onMqttTimerTick);
    mqttTimer_->start();

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
