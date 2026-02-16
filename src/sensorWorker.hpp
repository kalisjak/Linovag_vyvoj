#pragma once
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <string>

#include "config.hpp"
#include "runtimeConfig.hpp"

class SensorWorker : public QObject {
    Q_OBJECT
   public:
    explicit SensorWorker(QObject* parent = nullptr);

   signals:
    void sensorDS18(double v1, double v2, double v3, double v4, double v5);  // DS18B20 sensors
    void sensorDHT22Value(double temperature, double humidity);              // DHT22

    void visibleOneWireIds(const QStringList& ids);

    void heartbeat(const QString& name);  // pro watchdog ("sensors")

   public slots:
    void start();
    void stop();

    void setForcedEnabled(bool en);
    void setForcedTemps(double t1, double t2, double t3, double t4, double t5);

    // --- runtime set ID senzors ---
    void setSensor1Id(const QString& id);
    void setSensor2Id(const QString& id);
    void setSensor3Id(const QString& id);
    void setSensor4Id(const QString& id);
    void setSensor5Id(const QString& id);
    void setSensor6Id(const QString& id);

    QString sensor1Id() const;
    QString sensor2Id() const;
    QString sensor3Id() const;
    QString sensor4Id() const;
    QString sensor5Id() const;
    QString sensor6Id() const;

    // offsets (°C)
    void setSensor1Offset(double off);
    void setSensor2Offset(double off);
    void setSensor3Offset(double off);
    void setSensor4Offset(double off);
    void setSensor5Offset(double off);
    void setSensor6Offset(double off);

    // scan for visible 1-wire device addresses
    void refreshVisibleOneWireIds();

   private slots:
    void pollSensors();

   private:
    QTimer* timer_ = nullptr;
    QTimer* addrTimer_ = nullptr;

    const int swType_ = RuntimeConfig::softwareType();

    // DS18B20 ID
    std::string s1_;
    std::string s2_;
    std::string s3_;
    std::string s4_;
    std::string s5_;
    std::string s6_;  // DHT22 sensor ID (pro simulaci může být DS18B20)

    // offsets (°C)
    double off1_ = 0.0;
    double off2_ = 0.0;
    double off3_ = 0.0;
    double off4_ = 0.0;
    double off5_ = 0.0;
    double off6_ = 0.0;

    int dhtGpio_ = AppConfig::DHT22_GPIO;

    double readDS18B20(const std::string& deviceId);
    bool readDHT22(double& temperature, double& humidity);

    static inline double nanVal() { return std::numeric_limits<double>::quiet_NaN(); }

    bool forcedEnabled_ = false;
    double forcedT1_ = 5.0;
    double forcedT2_ = 5.0;
    double forcedT3_ = -10.0;
    double forcedT4_ = -10.0;
    double forcedT5_ = 22.2;
};
