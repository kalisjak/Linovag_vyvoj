#pragma once
#include <QObject>
#include <random>
#include <fstream>
#include <string>

QT_BEGIN_NAMESPACE
class QTimer;
QT_END_NAMESPACE

namespace QtMqtt { }
class QMqttClient;

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(double value1 READ value1 NOTIFY value1Changed)
    Q_PROPERTY(double value2 READ value2 NOTIFY value2Changed)
    Q_PROPERTY(bool   mqttConnected READ mqttConnected NOTIFY mqttConnectedChanged)
    Q_PROPERTY(QString serialNumber READ serialNumber NOTIFY serialNumberChanged)
    
    public:
    explicit Backend(QObject* parent = nullptr);
    
    double value1() const { return value1_; }
    double value2() const { return value2_; }
    bool   mqttConnected() const { return mqttConnected_; }
    double readDS18B20( std::string& deviceId);
    QString serialNumber() const;
    
    
    // z QML zadáš číslo jako text, např. "3.14"
    Q_INVOKABLE void sendMessage(const QString& msg);
    
    signals:
    void value1Changed();
    void value2Changed();
    void mqttConnectedChanged();
    void serialNumberChanged();
    
    private slots:
    void updateValues();
    void onMqttStateChanged(int s);
    void onMqttErrorChanged();
    
    private:
    // demo data
    double value1_ = 0.0;
    double value2_ = 0.0;
    QTimer* timer_ = nullptr;
    
    // sensors
    std::string s1= "28-0b24409ff61f";
    std::string s2= "28-0b2440f86631";

    std::mt19937 rng_;
    // std::uniform_real_distribution<double> dist_{-10.0, 30.0};

    // mqtt
    QMqttClient* mqtt_ = nullptr;
    bool mqttConnected_ = false;

    // broker config (případně načti z configu/env)
    const QString brokerHost_ = "192.168.3.101";
    const quint16 brokerPort_ = 1883;
    const QString brokerUser_ = "device1";
    const QString brokerPass_ = "pass1";
    const QString topic_      = "devices/device1/telemetry";
};
