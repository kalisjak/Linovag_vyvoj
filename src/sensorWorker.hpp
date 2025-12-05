#pragma once
#include <QObject>
#include <QTimer>
#include <string>

class SensorWorker : public QObject {
    Q_OBJECT
public:
    explicit SensorWorker(QObject* parent = nullptr);

signals:
    void sensorValues(double v1, double v2);   // pošle naměřené hodnoty do Backend
    void heartbeat(const QString& name);       // pro watchdog ("sensors")

public slots:
    void start();   // spustí timer
    void stop();    // zastaví timer

private slots:
    void pollSensors();

private:
    QTimer* timer_ = nullptr;

    // konkrétní ID máš teď v Backend01
    std::string s1_ = "28-0b24409ff61f";
    std::string s2_ = "28-0b2440f86631";

    double readDS18B20(const std::string& deviceId);
};
