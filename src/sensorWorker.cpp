#include "sensorWorker.hpp"

#include <QDebug>
#include <fstream>

SensorWorker::SensorWorker(QObject* parent) : QObject(parent) {
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &SensorWorker::pollSensors);

    // načti aktuální ID z runtime configu
    // (RuntimeConfig si uvnitř může brát default z AppConfig::SENSORx_ID)
    s1_ = RuntimeConfig::sensor1Id();
    s2_ = RuntimeConfig::sensor2Id();
    s3_ = RuntimeConfig::sensor3Id();
}

void SensorWorker::start() {
    // místo natvrdo 5000 ms použíj centrální konstantu
    timer_->start(AppConfig::SENSOR_POLL_INTERVAL_MS);
}

void SensorWorker::stop() {
    if (timer_) {
        timer_->stop();
    }
}

// ========== runtime změna ID senzorů ==========

void SensorWorker::setSensor1Id(const QString& id) {
    RuntimeConfig::setSensor1Id(id);   // uložíš do QSettings / configu
    s1_ = RuntimeConfig::sensor1Id();  // přenačteš (pro případ normalizace)
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

QString SensorWorker::sensor1Id() const { return QString::fromStdString(s1_); }

QString SensorWorker::sensor2Id() const { return QString::fromStdString(s2_); }

QString SensorWorker::sensor3Id() const { return QString::fromStdString(s3_); }

// ========== čtení DS18B20 ==========

double SensorWorker::readDS18B20(const std::string& deviceId) {
    const std::string path = "/sys/bus/w1/devices/" + deviceId + "/w1_slave";
    std::ifstream file(path);
    if (!file.is_open()) {
        // qWarning() << "[SensorWorker] Cannot open" << QString::fromStdString(path);
        return 5.0;
    }

    std::string line;
    std::getline(file, line);  // první řádek (CRC)
    std::getline(file, line);  // druhý řádek s "t="

    auto pos = line.find("t=");
    if (pos == std::string::npos) return -99.0;

    int temp_milli = std::stoi(line.substr(pos + 2));
    return temp_milli / 1000.0;
}

void SensorWorker::pollSensors() {
    // používáme lokální kopie ID, nečteme config při každém pollu
    double v1 = readDS18B20(s1_);
    double v2 = readDS18B20(s2_);
    double v3 = readDS18B20(s3_);

    emit sensorValues(v1, v2);
    emit evapValue(v3);
    emit heartbeat("sensors");
}
