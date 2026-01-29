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

    initLogManager();
}

void Backend::initLogManager() {
    logManager_.init(QString());

    connect(&logManager_, &LogManager::tempsHistoryChanged, this, &Backend::historyLogChanged);

    logManager_.setTempsSnapshotProvider([this]() {
        return buildTempsSnapshotLine();
    });

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
    qDebug() << "[Backend] Updating temperature values from SensorWorker";

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
    const QByteArray payload = TelemetryBuilder::buildPayload(value1_, value2_, value3_, value4_, value5_, value6_,
                                                              humidity_, targetTemp_, targetTemp2_, swType_);
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
        .arg(now.toString(QStringLiteral("HH:mm dd.MM.yy")), QString::number(targetTemp_, 'f', 1),
             QString::number(value1_, 'f', 1), QString::number(value3_, 'f', 1), QString::number(value5_, 'f', 1),
             QString::number(value6_, 'f', 1), QString::number(humidity_, 'f', 1));
}
