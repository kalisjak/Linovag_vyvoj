#include "sensorWorker.hpp"

#include <QDebug>
#include <QDir>
#include <cmath>
#include <fstream>

#ifdef LNVG_USE_PIGPIO
extern "C" {
#include <pigpio.h>
}
#endif

SensorWorker::SensorWorker(QObject* parent) : QObject(parent) {
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &SensorWorker::pollSensors);

    addrTimer_ = new QTimer(this);
    addrTimer_->setInterval(3000);
    connect(addrTimer_, &QTimer::timeout, this, &SensorWorker::refreshVisibleOneWireIds);

    // read actual ID from runtimeConfig
    s1_ = RuntimeConfig::sensor1Id();
    s2_ = RuntimeConfig::sensor2Id();
    s3_ = RuntimeConfig::sensor3Id();
    s4_ = RuntimeConfig::sensor4Id();
    s5_ = RuntimeConfig::sensor5Id();
    // simply real DHT22
    s6_ = RuntimeConfig::sensor6Id();

    // offsets
    off1_ = RuntimeConfig::sensor1Offset();
    off2_ = RuntimeConfig::sensor2Offset();
    off3_ = RuntimeConfig::sensor3Offset();
    off4_ = RuntimeConfig::sensor4Offset();
    off5_ = RuntimeConfig::sensor5Offset();
    off6_ = RuntimeConfig::sensor6Offset();

#ifdef LNVG_USE_PIGPIO
    static bool pigpioInitialized = false;
    if (!pigpioInitialized) {
        if (gpioInitialise() < 0) {
            qWarning() << "pigpio init failed IN SENSOR WORKER!";
        } else {
            pigpioInitialized = true;
        }
    }
#endif
}

void SensorWorker::start() {
    qInfo() << "[SensorWorker] Starting sensor polling...";
    timer_->start(AppConfig::SENSOR_POLL_INTERVAL_MS);
    refreshVisibleOneWireIds();
    if (addrTimer_) addrTimer_->start();
}

void SensorWorker::stop() {
    if (timer_) timer_->stop();
    if (addrTimer_) addrTimer_->stop();
}

// ========== runtime změna ID senzorů ==========

void SensorWorker::setSensor1Id(const QString& id) {
    RuntimeConfig::setSensor1Id(id);
    s1_ = RuntimeConfig::sensor1Id();
    // qInfo() << "[SensorWorker] Sensor1 ID changed to" << id;
}

void SensorWorker::setSensor2Id(const QString& id) {
    RuntimeConfig::setSensor2Id(id);
    s2_ = RuntimeConfig::sensor2Id();
    // qInfo() << "[SensorWorker] Sensor2 ID changed to" << id;
}

void SensorWorker::setSensor3Id(const QString& id) {
    RuntimeConfig::setSensor3Id(id);
    s3_ = RuntimeConfig::sensor3Id();
    // qInfo() << "[SensorWorker] Sensor3 ID changed to" << id;
}
void SensorWorker::setSensor4Id(const QString& id) {
    RuntimeConfig::setSensor4Id(id);
    s4_ = RuntimeConfig::sensor4Id();
}
void SensorWorker::setSensor5Id(const QString& id) {
    RuntimeConfig::setSensor5Id(id);
    s5_ = RuntimeConfig::sensor5Id();
}

void SensorWorker::setSensor6Id(const QString& id) {
    RuntimeConfig::setSensor6Id(id);
    s6_ = RuntimeConfig::sensor6Id();
}

QString SensorWorker::sensor1Id() const { return QString::fromStdString(s1_); }
QString SensorWorker::sensor2Id() const { return QString::fromStdString(s2_); }
QString SensorWorker::sensor3Id() const { return QString::fromStdString(s3_); }
QString SensorWorker::sensor4Id() const { return QString::fromStdString(s4_); }
QString SensorWorker::sensor5Id() const { return QString::fromStdString(s5_); }
QString SensorWorker::sensor6Id() const { return QString::fromStdString(s6_); }

void SensorWorker::setSensor1Offset(double off) {
    RuntimeConfig::setSensor1Offset(off);
    off1_ = RuntimeConfig::sensor1Offset();
}
void SensorWorker::setSensor2Offset(double off) {
    RuntimeConfig::setSensor2Offset(off);
    off2_ = RuntimeConfig::sensor2Offset();
}
void SensorWorker::setSensor3Offset(double off) {
    RuntimeConfig::setSensor3Offset(off);
    off3_ = RuntimeConfig::sensor3Offset();
}
void SensorWorker::setSensor4Offset(double off) {
    RuntimeConfig::setSensor4Offset(off);
    off4_ = RuntimeConfig::sensor4Offset();
}
void SensorWorker::setSensor5Offset(double off) {
    RuntimeConfig::setSensor5Offset(off);
    off5_ = RuntimeConfig::sensor5Offset();
}
void SensorWorker::setSensor6Offset(double off) {
    RuntimeConfig::setSensor6Offset(off);
    off6_ = RuntimeConfig::sensor6Offset();
}

void SensorWorker::refreshVisibleOneWireIds() {
    QStringList ids;
#ifdef LNVG_USE_PIGPIO
    QDir dir(QStringLiteral("/sys/bus/w1/devices"));
    if (dir.exists()) {
        const QStringList entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString& e : entries) {
            if (e.startsWith(QStringLiteral("28-"))) ids.append(e);
        }
        ids.sort();
    }
#endif
    emit visibleOneWireIds(ids);
}

// ========== čtení DS18B20 ==========
double SensorWorker::readDS18B20(const std::string& deviceId) {
    // qDebug() << "[SensorWorker] Reading DS18B20 sensor" << QString::fromStdString(deviceId);

    if (deviceId.empty()) return nanVal();

#ifdef LNVG_USE_PIGPIO

    const std::string path = "/sys/bus/w1/devices/" + deviceId + "/w1_slave";
    std::ifstream file(path);
    if (!file.is_open()) {
        qWarning() << "[SensorWorker] Cannot open" << QString::fromStdString(path);
        return nanVal();
    }

    std::string line1, line2;
    std::getline(file, line1);  // CRC
    std::getline(file, line2);  // data ("t=")

    // pokud CRC neOK, vrat NaN
    if (line1.find("YES") == std::string::npos) {
        qWarning() << "[SensorWorker] CRC check failed for" << QString::fromStdString(deviceId);
        return nanVal();
    }

    const auto pos = line2.find("t=");
    if (pos == std::string::npos) return nanVal();

    const int temp_milli = std::stoi(line2.substr(pos + 2));
    return temp_milli / 1000.0;
#else
    return nanVal();
#endif
}

// ========== čtení DHT22 ==========

bool SensorWorker::readDHT22(double& temperature, double& humidity) {
#ifdef LNVG_USE_PIGPIO

    qDebug() << "[SensorWorker] Reading DHT22 sensor - it's a simulation in this version";

    temperature = readDS18B20(s6_);  // pro simulaci použijeme DS18B201
    humidity = 36.2;                 // pevná vlhkost

    return true;
#else
    temperature = nanVal();
    humidity = nanVal();
    return true;
#endif
}

auto applyOff = [](double v, double off) -> double { return std::isnan(v) ? v : (v + off); };
auto checkValidity = [](double v) -> double {
    return (std::isnan(v) || v <= -30 || v >= 55) ? std::numeric_limits<double>::quiet_NaN() : v;
};

void SensorWorker::pollSensors() {
    emit heartbeat(QStringLiteral("sensors"));

    // qDebug() << "[SensorWorker] Polling sensors...";

    double v1 = nanVal(), v2 = nanVal(), v3 = nanVal(), v4 = nanVal(), v5 = nanVal();
    double tempIntake = nanVal(), humIntake = nanVal();

    if (forcedEnabled_) {
        v1 = forcedT1_;
        v2 = forcedT2_;
        v3 = forcedT3_;
        v4 = forcedT4_;
        v5 = forcedT5_;
    }

    if (!forcedEnabled_) {
        if (swType_ == 22) {
            v1 = readDS18B20(s1_);
            v2 = readDS18B20(s2_);
            v3 = readDS18B20(s3_);
            v4 = readDS18B20(s4_);
            v5 = readDS18B20(s5_);
        } else {  // typ 3
            v1 = readDS18B20(s1_);
            v3 = readDS18B20(s3_);
            v5 = readDS18B20(s5_);
        }
    }

    if (!readDHT22(tempIntake, humIntake)) {
        qWarning() << "DHT22 read failed";
    }

    v1 = applyOff(checkValidity(v1), off1_);
    v2 = applyOff(checkValidity(v2), off2_);
    v3 = applyOff(checkValidity(v3), off3_);
    v4 = applyOff(checkValidity(v4), off4_);
    v5 = applyOff(checkValidity(v5), off5_);
    tempIntake = applyOff(checkValidity(tempIntake), off6_);

    emit sensorDS18(v1, v2, v3, v4, v5);
    emit sensorDHT22Value(tempIntake, humIntake);
}

void SensorWorker::setForcedEnabled(bool en) { forcedEnabled_ = en; }

void SensorWorker::setForcedTemps(double t1, double t2, double t3, double t4, double t5) {
    forcedT1_ = t1;
    forcedT2_ = t2;
    forcedT3_ = t3;
    forcedT4_ = t4;
    forcedT5_ = t5;
}