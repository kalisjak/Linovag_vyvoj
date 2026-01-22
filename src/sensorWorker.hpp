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
    void sensorValWell(double v1, double v2);   // pro Backend (GUI)
    void sensorValEvap(double v3, double v4);   // vyparnik
    void sensorValCond(double v5);              // kondenzator
    void heartbeat(const QString& name);        // pro watchdog ("sensors")

public slots:
    void start();   // spustí timer
    void stop();    // zastaví timer

    void setForcedEnabled(bool en);
    void setForcedTemps(double t1, double t2, double t3, double t4, double t5);

    // --- runtime nastavení ID senzorů (bez rekompilace) ---

    void setSensor1Id(const QString& id);
    void setSensor2Id(const QString& id);
    void setSensor3Id(const QString& id);
    void setSensor4Id(const QString& id);
    void setSensor5Id(const QString& id);

    QString sensor1Id() const;
    QString sensor2Id() const;
    QString sensor3Id() const;
    QString sensor4Id() const;
    QString sensor5Id() const;

private slots:
    void pollSensors();

private:
    QTimer* timer_ = nullptr;

    // aktuální ID senzorů, používané při čtení
    std::string s1_;
    std::string s2_;
    std::string s3_;
    std::string s4_;
    std::string s5_;

    double readDS18B20(const std::string& deviceId);

    bool forcedEnabled_ = false;
    double forcedT1_ = 5.0;
    double forcedT2_ = 5.0;
    double forcedT3_ = -10.0;
    double forcedT4_ = -10.0;
    double forcedT5_ = 22.2;
};