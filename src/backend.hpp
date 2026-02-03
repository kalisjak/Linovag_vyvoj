#pragma once
#include <QByteArray>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QtGlobal>
#include <fstream>
#include <random>
#include <string>

#include "config.hpp"
#include "logManager.hpp"
#include "runtimeConfig.hpp"
#include "telemetryBuilder.hpp"

QT_BEGIN_NAMESPACE
class QTimer;
QT_END_NAMESPACE

class Backend : public QObject {
    Q_OBJECT

    // --- Live values (6 temperatures + humidity) ---
    Q_PROPERTY(double value1 READ value1 NOTIFY value1Changed)        // well1
    Q_PROPERTY(double value2 READ value2 NOTIFY value2Changed)        // well2
    Q_PROPERTY(double value3 READ value3 NOTIFY value3Changed)        // evap1
    Q_PROPERTY(double value4 READ value4 NOTIFY value4Changed)        // evap2
    Q_PROPERTY(double value5 READ value5 NOTIFY value5Changed)        // kondenzator (id5)
    Q_PROPERTY(double value6 READ value6 NOTIFY value6Changed)        // nasavani temp (dht22)
    Q_PROPERTY(double humidity READ humidity NOTIFY humidityChanged)  // vlhkost (dht22)

    Q_PROPERTY(bool mqttConnected READ mqttConnected NOTIFY mqttConnectedChanged)
    Q_PROPERTY(QString serialNumber READ serialNumber NOTIFY serialNumberChanged)

    Q_PROPERTY(int softwareType READ softwareType WRITE setSoftwareType NOTIFY softwareTypeChanged)
    Q_PROPERTY(QString softwareTypeLabel READ softwareTypeLabel NOTIFY softwareTypeChanged)

    Q_PROPERTY(double targetTemp READ targetTemp WRITE setTargetTemp NOTIFY targetTempChanged)
    // Jen typ 2+2
    Q_PROPERTY(double targetTemp2 READ targetTemp2 WRITE setTargetTemp2 NOTIFY targetTemp2Changed)

    Q_PROPERTY(QStringList historyLog READ historyLog NOTIFY historyLogChanged)

    Q_PROPERTY(bool errorActive READ errorActive NOTIFY errorActiveChanged)

    Q_PROPERTY(bool coolingActive READ coolingActive NOTIFY coolingActiveChanged)
    Q_PROPERTY(bool defrostActive READ defrostActive NOTIFY defrostActiveChanged)
    Q_PROPERTY(bool compressorOn READ compressorOn NOTIFY compressorOnChanged)
    Q_PROPERTY(bool dripHoldActive READ dripHoldActive NOTIFY dripHoldActiveChanged)

    // Jen typ 2+2
    Q_PROPERTY(bool cooling2Active READ cooling2Active NOTIFY cooling2ActiveChanged)
    Q_PROPERTY(bool defrost2Active READ defrost2Active NOTIFY defrost2ActiveChanged)
    Q_PROPERTY(bool compressor2On READ compressor2On NOTIFY compressor2OnChanged)
    Q_PROPERTY(bool dripHold2Active READ dripHold2Active NOTIFY dripHold2ActiveChanged)

    Q_PROPERTY(QString reclaimOrderNumber READ reclaimOrderNumber NOTIFY reclaimInfoChanged)
    Q_PROPERTY(QString reclaimEmail READ reclaimEmail NOTIFY reclaimInfoChanged)

    // forced sensors for testing
    Q_PROPERTY(bool forcedSensors READ forcedSensors WRITE setForcedSensors NOTIFY forcedSensorsChanged)
    Q_PROPERTY(double forcedTemp1 READ forcedTemp1 WRITE setForcedTemp1 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp2 READ forcedTemp2 WRITE setForcedTemp2 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp3 READ forcedTemp3 WRITE setForcedTemp3 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp4 READ forcedTemp4 WRITE setForcedTemp4 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp5 READ forcedTemp5 WRITE setForcedTemp5 NOTIFY forcedTempsChanged)

    // Power pins (future page)
    Q_PROPERTY(bool power1On READ power1On WRITE setPower1On NOTIFY power1OnChanged)
    Q_PROPERTY(bool power2On READ power2On WRITE setPower2On NOTIFY power2OnChanged)

   public:
    explicit Backend(QObject* parent = nullptr);

    int softwareType() const { return swType_; }
    QString softwareTypeLabel() const { return swType_ == 22 ? QStringLiteral("Vana typ-2+2") : QStringLiteral("Vana typ-3"); }

    double value1() const { return value1_; }
    double value2() const { return value2_; }
    double value3() const { return value3_; }
    double value4() const { return value4_; }
    double value5() const { return value5_; }
    double value6() const { return value6_; }
    double humidity() const { return humidity_; }

    double targetTemp() const { return targetTemp_; }
    double targetTemp2() const { return targetTemp2_; }

    // forced sensors for testing
    bool forcedSensors() const { return forcedSensors_; }

    double forcedTemp1() const { return forcedT1_; }
    double forcedTemp2() const { return forcedT2_; }
    double forcedTemp3() const { return forcedT3_; }
    double forcedTemp4() const { return forcedT4_; }
    double forcedTemp5() const { return forcedT5_; }

    bool mqttConnected() const { return mqttConnected_; }

    bool errorActive() const { return errorActive_; }

    bool coolingActive() const { return coolingActive_; }
    bool defrostActive() const { return defrostActive_; }
    bool compressorOn() const { return compressorOn_; }
    bool dripHoldActive() const { return dripHoldActive_; }

    bool cooling2Active() const { return cooling2Active_; }
    bool defrost2Active() const { return defrost2Active_; }
    bool compressor2On() const { return compressor2On_; }
    bool dripHold2Active() const { return dripHold2Active_; }

    QString serialNumber() const { return RuntimeConfig::deviceSerial(); }
    QString reclaimOrderNumber() const { return RuntimeConfig::reclaimOrderNumber(); };
    QString reclaimEmail() const { return RuntimeConfig::reclaimEmail(); };
    QStringList historyLog() const { return logManager_.tempsHistory(); }

    bool power1On() const { return power1On_; }
    bool power2On() const { return power2On_; }

    Q_INVOKABLE void sendMessage(const QString& msg);

   public slots:
    void setTargetTemp(double t);
    void setTargetTemp2(double t);

    void setSoftwareType(int type);

    void onMqttTimerTick();

    // slots for updating values from SensorWorker
    void updateTempValue(double v1, double v2, double v3, double v4, double v5);
    void updateIntakeValue(double v6, double hum);

    void updateMqttConnected(bool ok);

    void updateCoolingState(bool coolingActive, bool defrostActive, bool compressorOn, bool dripHoldActive);
    void updateCoolingState2(bool coolingActive, bool defrostActive, bool compressorOn, bool dripHoldActive);

    void setErrorActive(bool active);

    void setReclaimOrderNumber(const QString& number);
    void setReclaimEmail(const QString& email);

    void setForcedSensors(bool en);
    void setForcedTemp1(double v);
    void setForcedTemp2(double v);
    void setForcedTemp3(double v);
    void setForcedTemp4(double v);
    void setForcedTemp5(double v);

    void setPower1On(bool on);
    void setPower2On(bool on);

   signals:
    void value1Changed();
    void value2Changed();
    void value3Changed();
    void value4Changed();
    void value5Changed();
    void value6Changed();
    void humidityChanged();

    void targetTempChanged();
    void targetTemp2Changed();
    void softwareTypeChanged();

    void mqttConnectedChanged();
    void serialNumberChanged();
    void historyLogChanged();

    // signály směrem k workerům
    void publishMqtt(const QByteArray& payload);

    void errorActiveChanged();

    void coolingActiveChanged();
    void defrostActiveChanged();
    void compressorOnChanged();
    void dripHoldActiveChanged();
    
    void cooling2ActiveChanged();
    void defrost2ActiveChanged();
    void compressor2OnChanged();
    void dripHold2ActiveChanged();

    void reclaimInfoChanged();

    // forced sensors
    void forcedSensorsChanged();
    void forcedTempsChanged();

    // requesty do SensorWorkeru
    void requestForcedEnabled(bool en);
    void requestForcedTemps(double t1, double t2, double t3, double t4, double t5);

    // power worker zatim neexistuje
    void requestPower1(bool on);
    void requestPower2(bool on);
    void power1OnChanged();
    void power2OnChanged();

   private:
    double value1_ = 0.0;
    double value2_ = 0.0;
    double value3_ = 0.0;
    double value4_ = 0.0;
    double value5_ = 22.2;
    double value6_ = 22.2;
    double humidity_ = 50.0;

    double targetTemp_ = 5.0;
    double targetTemp2_ = 5.0;

    int swType_ = 3;

    std::mt19937 rng_;
    bool mqttConnected_ = false;
    bool errorActive_ = false;

    bool coolingActive_ = false;
    bool defrostActive_ = false;
    bool compressorOn_ = false;
    bool dripHoldActive_ = false;
    
    bool cooling2Active_ = false;
    bool defrost2Active_ = false;
    bool compressor2On_ = false;
    bool dripHold2Active_ = false;

    // forced sensors for testing
    bool forcedSensors_ = false;
    double forcedT1_ = 5.0;
    double forcedT2_ = 5.0;
    double forcedT3_ = -8.0;
    double forcedT4_ = 20.0;
    double forcedT5_ = 20.0;

    bool power1On_ = false;
    bool power2On_ = false;

    static constexpr int mqtt_push_time = AppConfig::MQTT_POLL_INTERVAL_MS;
    QTimer* mqttTimer_ = nullptr;  // nový timer na MQTT payload

    LogManager logManager_;
    void initLogManager();

    QString buildTempsSnapshotLine() const;
};
