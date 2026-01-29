#include "sensorWorker.hpp"

#include <QDebug>
#include <QDir>
#include <fstream>

#ifdef LNVG_USE_PIGPIO
extern "C" {
#include <pigpio.h>
}
#endif

SensorWorker::SensorWorker(QObject* parent) : QObject(parent) {
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &SensorWorker::pollSensors);

    // read actual ID from runtimeConfig
    s1_ = RuntimeConfig::sensor1Id();
    s2_ = RuntimeConfig::sensor2Id();
    s3_ = RuntimeConfig::sensor3Id();
    s4_ = RuntimeConfig::sensor4Id();
    s5_ = RuntimeConfig::sensor5Id();
    // simply real DHT22
    s6_ = RuntimeConfig::sensor6Id();

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
    timer_->start(AppConfig::SENSOR_POLL_INTERVAL_MS); }

void SensorWorker::stop() {
    if (timer_) {
        timer_->stop();
    }
}

// ========== runtime změna ID senzorů ==========

void SensorWorker::setSensor1Id(const QString& id) {
    RuntimeConfig::setSensor1Id(id);
    s1_ = RuntimeConfig::sensor1Id();
    qInfo() << "[SensorWorker] Sensor1 ID changed to" << id;
}

void SensorWorker::setSensor2Id(const QString& id) {
    RuntimeConfig::setSensor2Id(id);
    s2_ = RuntimeConfig::sensor2Id();
    qInfo() << "[SensorWorker] Sensor2 ID changed to" << id;
}

void SensorWorker::setSensor3Id(const QString& id) {
    RuntimeConfig::setSensor3Id(id);
    s3_ = RuntimeConfig::sensor3Id();
    qInfo() << "[SensorWorker] Sensor3 ID changed to" << id;
}
void SensorWorker::setSensor4Id(const QString& id) {
    RuntimeConfig::setSensor4Id(id);
    s4_ = RuntimeConfig::sensor4Id();
    qInfo() << "[SensorWorker] Sensor4 ID changed to" << id;
}
void SensorWorker::setSensor5Id(const QString& id) {
    RuntimeConfig::setSensor5Id(id);
    s5_ = RuntimeConfig::sensor5Id();
    qInfo() << "[SensorWorker] Sensor5 ID changed to" << id;
}

QString SensorWorker::sensor1Id() const { return QString::fromStdString(s1_); }

QString SensorWorker::sensor2Id() const { return QString::fromStdString(s2_); }

QString SensorWorker::sensor3Id() const { return QString::fromStdString(s3_); }

QString SensorWorker::sensor4Id() const { return QString::fromStdString(s4_); }

QString SensorWorker::sensor5Id() const { return QString::fromStdString(s5_); }

QString SensorWorker::sensor6Id() const { return QString::fromStdString(s6_); }


// ========== čtení DS18B20 ==========
double SensorWorker::readDS18B20(const std::string& deviceId) {
    qDebug() << "[SensorWorker] Reading DS18B20 sensor" << QString::fromStdString(deviceId);

    if (deviceId.empty()) return nanVal();

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
}

// ========== čtení DHT22 ==========

bool SensorWorker::readDHT22(double& temperature, double& humidity) {
#ifdef LNVG_USE_PIGPIO

    qDebug() << "[SensorWorker] Reading DHT22 sensor - it's a simulation in this version";

    temperature = readDS18B20(s6_);  // pro simulaci použijeme DS18B201
    humidity = 36.2;              // pevná vlhkost

    // const int gpio = dhtGpio_;

    // // start sekvence
    // gpioSetMode(gpio, PI_OUTPUT);
    // gpioWrite(gpio, PI_HIGH);
    // gpioDelay(500000);  // 500 ms stabilizace

    // gpioWrite(gpio, PI_LOW);
    // gpioDelay(2000);  // 2 ms low
    // gpioWrite(gpio, PI_HIGH);
    // gpioDelay(40);  // 20–40 µs

    // gpioSetMode(gpio, PI_INPUT);

    // // nasbíráme pulzy
    // uint32_t lastTick = gpioTick();
    // int lastLevel = gpioRead(gpio);

    // // čekání na první přechody z čtecí sekvence
    // int transitions = 0;
    // while (transitions < 3) {
    //     int level = gpioRead(gpio);
    //     if (level != lastLevel) {
    //         lastLevel = level;
    //         lastTick = gpioTick();
    //         ++transitions;
    //     }
    //     gpioDelay(1);
    // }

    // int bits[40] = {0};
    // int bitIndex = 0;

    // while (bitIndex < 40) {
    //     // čekej na LOW->HIGH
    //     int level = gpioRead(gpio);
    //     while (level == 0) {
    //         level = gpioRead(gpio);
    //     }
    //     uint32_t startTick = gpioTick();

    //     // HIGH
    //     while (level == 1) {
    //         level = gpioRead(gpio);
    //         if ((gpioTick() - startTick) > 200) {
    //             break;  // timeout
    //         }
    //     }
    //     uint32_t diff = gpioTick() - startTick;

    //     // krátký puls ~26-28 µs => 0, dlouhý ~70 µs => 1
    //     bits[bitIndex] = (diff > 50) ? 1 : 0;
    //     ++bitIndex;
    // }

    // // složení do bajtů
    // uint8_t data[5] = {0};
    // for (int i = 0; i < 40; ++i) {
    //     data[i / 8] <<= 1;
    //     data[i / 8] |= bits[i];
    // }

    // uint8_t checksum = (uint8_t)((data[0] + data[1] + data[2] + data[3]) & 0xFF);
    // if (checksum != data[4]) {
    //     qWarning() << "DHT22 checksum error";
    //     return false;
    // }

    // // DHT22 – 16bit, první dva bajty jsou vlhkost, další dva teplota
    // int16_t rawHum = (data[0] << 8) | data[1];
    // int16_t rawTemp = (data[2] << 8) | data[3];

    // humidity = rawHum / 10.0;
    // if (rawTemp & 0x8000) {
    //     rawTemp = rawTemp & 0x7FFF;
    //     temperature = -rawTemp / 10.0;
    // } else {
    //     temperature = rawTemp / 10.0;
    // }

    return true;
#else
    temperature = nanVal();
    humidity = nanVal();
    return true;
#endif
}

void SensorWorker::pollSensors() {
    emit heartbeat(QStringLiteral("sensors"));

    qDebug() << "[SensorWorker] Polling sensors...";

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
        } else { // typ 3
            v1 = readDS18B20(s1_);
            v3 = readDS18B20(s3_);
            v5 = readDS18B20(s5_);
        }
    }

    if (!readDHT22(tempIntake, humIntake)) {
        qWarning() << "DHT22 read failed";
    }

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