#include "SensorWorker.hpp"
#include <QDebug>
#include <fstream>

SensorWorker::SensorWorker(QObject* parent)
    : QObject(parent)
{
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout,
            this, &SensorWorker::pollSensors);
}

void SensorWorker::start()
{
    timer_->start(5000);   // stejné jako teď v Backend::updateValues
}

void SensorWorker::stop()
{
    timer_->stop();
}

double SensorWorker::readDS18B20(const std::string& deviceId)
{
    std::string path = "/sys/bus/w1/devices/" + deviceId + "/w1_slave";
    std::ifstream file(path);
    if (!file.is_open()) return 5.0;      // stejně jako máš teď

    std::string line;
    std::getline(file, line);             // první řádek
    if (line.find("YES") == std::string::npos) return -99.0;
    std::getline(file, line);             // druhý řádek
    auto pos = line.find("t=");
    if (pos == std::string::npos) return -99.0;

    int temp_milli = std::stoi(line.substr(pos + 2));
    return temp_milli / 1000.0;
}

void SensorWorker::pollSensors()
{
    double v1 = readDS18B20(s1_);
    double v2 = readDS18B20(s2_);

    emit sensorValues(v1, v2);
    emit heartbeat("sensors");
}
