#pragma once
#include <QObject>
#include <QTimer>
#include <string>

#include "config.hpp"
#include "runtimeConfig.hpp"

class SensorWorker : public QObject {
    Q_OBJECT
public:
    explicit SensorWorker(QObject* parent = nullptr);

signals:
    void sensorValues(double v1, double v2);   // pro Backend (GUI)
    void evapValue(double v3);                // výparník (senzor 3)
    void heartbeat(const QString& name);      // pro watchdog ("sensors")

public slots:
    void start();   // spustí timer
    void stop();    // zastaví timer

    void setForcedEnabled(bool en);
    void setForcedTemps(double t1, double t2, double t3);

    // --- runtime nastavení ID senzorů (bez rekompilace) ---

    void setSensor1Id(const QString& id);
    void setSensor2Id(const QString& id);
    void setSensor3Id(const QString& id);

    QString sensor1Id() const;
    QString sensor2Id() const;
    QString sensor3Id() const;

private slots:
    void pollSensors();

private:
    QTimer* timer_ = nullptr;

    // aktuální ID senzorů, používané při čtení
    std::string s1_;
    std::string s2_;
    std::string s3_;

    double readDS18B20(const std::string& deviceId);

    bool forcedEnabled_ = false;
    double forcedT1_ = 5.0;
    double forcedT2_ = 5.0;
    double forcedT3_ = -10.0;
};
