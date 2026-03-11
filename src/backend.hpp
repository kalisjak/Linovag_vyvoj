#pragma once
#include <QByteArray>
#include <QDateTime>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
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
    Q_PROPERTY(QString appLanguage READ appLanguage WRITE setAppLanguage NOTIFY appLanguageChanged)
    Q_PROPERTY(QString wifiLastMessage READ wifiLastMessage NOTIFY wifiLastMessageChanged)
    Q_PROPERTY(bool wifiConnected READ wifiConnected NOTIFY wifiConnectedChanged)
    Q_PROPERTY(bool ethernetConnected READ ethernetConnected NOTIFY ethernetConnectedChanged)
    Q_PROPERTY(bool wifiAuthFailure READ wifiAuthFailure NOTIFY wifiAuthFailureChanged)

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

    Q_PROPERTY(bool autoDefrostEnabled READ autoDefrostEnabled WRITE setAutoDefrostEnabled NOTIFY autoDefrostEnabledChanged)
    Q_PROPERTY(int autoDefrostTime1Min READ autoDefrostTime1Min WRITE setAutoDefrostTime1Min NOTIFY autoDefrostTimeChanged)
    Q_PROPERTY(int autoDefrostTime2Min READ autoDefrostTime2Min WRITE setAutoDefrostTime2Min NOTIFY autoDefrostTimeChanged)

    // Bath enable/disable (user OFF = compressor OFF + fans OFF)
    Q_PROPERTY(bool bath1Enabled READ bath1Enabled WRITE setBath1Enabled NOTIFY bath1EnabledChanged)
    Q_PROPERTY(bool bath2Enabled READ bath2Enabled WRITE setBath2Enabled NOTIFY bath2EnabledChanged)

    Q_PROPERTY(QString reclaimOrderNumber READ reclaimOrderNumber NOTIFY reclaimInfoChanged)
    Q_PROPERTY(QString reclaimEmail READ reclaimEmail NOTIFY reclaimInfoChanged)
    Q_PROPERTY(QString customEmail READ customEmail NOTIFY reclaimInfoChanged)
    Q_PROPERTY(bool customerScreenLocked READ customerScreenLocked NOTIFY customerScreenLockChanged)
    Q_PROPERTY(bool customerAutoLockEnabled READ customerAutoLockEnabled WRITE setCustomerAutoLockEnabled NOTIFY customerLockConfigChanged)
    Q_PROPERTY(QString customerLockPin READ customerLockPin NOTIFY customerLockConfigChanged)
    Q_PROPERTY(bool serviceModeEnabled READ serviceModeEnabled NOTIFY serviceModeEnabledChanged)

    // forced sensors for testing
    Q_PROPERTY(bool forcedSensors READ forcedSensors WRITE setForcedSensors NOTIFY forcedSensorsChanged)
    Q_PROPERTY(double forcedTemp1 READ forcedTemp1 WRITE setForcedTemp1 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp2 READ forcedTemp2 WRITE setForcedTemp2 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp3 READ forcedTemp3 WRITE setForcedTemp3 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp4 READ forcedTemp4 WRITE setForcedTemp4 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp5 READ forcedTemp5 WRITE setForcedTemp5 NOTIFY forcedTempsChanged)

    // Visible 1-wire IDs (scanned)
    Q_PROPERTY(QStringList visibleOneWireIds READ visibleOneWireIds NOTIFY visibleOneWireIdsChanged)

    // Sensor IDs (runtime config)
    Q_PROPERTY(QString sensor1Id READ sensor1Id WRITE setSensor1Id NOTIFY sensorConfigChanged)
    Q_PROPERTY(QString sensor2Id READ sensor2Id WRITE setSensor2Id NOTIFY sensorConfigChanged)
    Q_PROPERTY(QString sensor3Id READ sensor3Id WRITE setSensor3Id NOTIFY sensorConfigChanged)
    Q_PROPERTY(QString sensor4Id READ sensor4Id WRITE setSensor4Id NOTIFY sensorConfigChanged)
    Q_PROPERTY(QString sensor5Id READ sensor5Id WRITE setSensor5Id NOTIFY sensorConfigChanged)
    Q_PROPERTY(QString sensor6Id READ sensor6Id WRITE setSensor6Id NOTIFY sensorConfigChanged)

    // Offsets
    Q_PROPERTY(double sensor1Offset READ sensor1Offset WRITE setSensor1Offset NOTIFY sensorConfigChanged)
    Q_PROPERTY(double sensor2Offset READ sensor2Offset WRITE setSensor2Offset NOTIFY sensorConfigChanged)
    Q_PROPERTY(double sensor3Offset READ sensor3Offset WRITE setSensor3Offset NOTIFY sensorConfigChanged)
    Q_PROPERTY(double sensor4Offset READ sensor4Offset WRITE setSensor4Offset NOTIFY sensorConfigChanged)
    Q_PROPERTY(double sensor5Offset READ sensor5Offset WRITE setSensor5Offset NOTIFY sensorConfigChanged)
    Q_PROPERTY(double sensor6Offset READ sensor6Offset WRITE setSensor6Offset NOTIFY sensorConfigChanged)

    // Power pins (future page)
    Q_PROPERTY(bool power1On READ power1On WRITE setPower1On NOTIFY power1OnChanged)
    Q_PROPERTY(bool power2On READ power2On WRITE setPower2On NOTIFY power2OnChanged)

   public:
    explicit Backend(QObject* parent = nullptr);

    int softwareType() const { return swType_; }
    QString softwareTypeLabel() const { return swType_ == 22 ? QStringLiteral("Vana typ-2+2") : QStringLiteral("Vana typ-3"); }
    QString appLanguage() const { return appLanguage_; }
    QString wifiLastMessage() const { return wifiLastMessage_; }
    bool wifiConnected() const { return wifiConnected_; }
    bool ethernetConnected() const { return ethernetConnected_; }
    bool wifiAuthFailure() const { return wifiAuthFailure_; }

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

    bool bath1Enabled() const { return bath1Enabled_; }
    bool bath2Enabled() const { return bath2Enabled_; }

    // Auto defrost schedule (cached from runtime config)
    bool autoDefrostEnabled() const { return autoDefrostEnabled_; }
    int autoDefrostTime1Min() const { return autoDefrostTime1Min_; }
    int autoDefrostTime2Min() const { return autoDefrostTime2Min_; }

    QString serialNumber() const { return RuntimeConfig::deviceSerial(); }
    QString reclaimOrderNumber() const { return RuntimeConfig::reclaimOrderNumber(); };
    QString reclaimEmail() const { return RuntimeConfig::reclaimEmail(); };
    QString customEmail() const { return RuntimeConfig::customEmail(); };
    bool customerScreenLocked() const { return customerScreenLocked_; }
    bool customerAutoLockEnabled() const { return customerAutoLockEnabled_; }
    QString customerLockPin() const { return customerLockPin_; }
    bool serviceModeEnabled() const { return serviceModeEnabled_; }
    QStringList historyLog() const { return logManager_.tempsHistory(); }

    QStringList visibleOneWireIds() const { return visibleOneWireIds_; }

    QString sensor1Id() const { return QString::fromStdString(RuntimeConfig::sensor1Id()); }
    QString sensor2Id() const { return QString::fromStdString(RuntimeConfig::sensor2Id()); }
    QString sensor3Id() const { return QString::fromStdString(RuntimeConfig::sensor3Id()); }
    QString sensor4Id() const { return QString::fromStdString(RuntimeConfig::sensor4Id()); }
    QString sensor5Id() const { return QString::fromStdString(RuntimeConfig::sensor5Id()); }
    QString sensor6Id() const { return QString::fromStdString(RuntimeConfig::sensor6Id()); }

    double sensor1Offset() const { return RuntimeConfig::sensor1Offset(); }
    double sensor2Offset() const { return RuntimeConfig::sensor2Offset(); }
    double sensor3Offset() const { return RuntimeConfig::sensor3Offset(); }
    double sensor4Offset() const { return RuntimeConfig::sensor4Offset(); }
    double sensor5Offset() const { return RuntimeConfig::sensor5Offset(); }
    double sensor6Offset() const { return RuntimeConfig::sensor6Offset(); }

    bool power1On() const { return power1On_; }
    bool power2On() const { return power2On_; }

    Q_INVOKABLE void sendMessage(const QString& msg);
    Q_INVOKABLE QVariantList wifiScanNetworks(bool forceRescan = false);
    Q_INVOKABLE bool wifiConnect(const QString& ssid, const QString& username, const QString& password, bool enterprise,
                                 const QString& bssid = QString());
    Q_INVOKABLE bool wifiDisconnect(const QString& ssid = QString());
    Q_INVOKABLE bool wifiForget(const QString& ssid);
    Q_INVOKABLE bool unlockCustomerScreen(const QString& pin);
    Q_INVOKABLE void lockCustomerScreen();
    Q_INVOKABLE bool unlockServiceMode(const QString& pin);
    Q_INVOKABLE void lockServiceMode();

   public slots:
    void setTargetTemp(double t);
    void setTargetTemp2(double t);

    void setSoftwareType(int type);
    void setAppLanguage(const QString& lang);

    void onMqttTimerTick();

    // slots for updating values from SensorWorker
    void updateTempValue(double v1, double v2, double v3, double v4, double v5);
    void updateIntakeValue(double v6, double hum);

    void updateMqttConnected(bool ok);

    void updateCoolingState(bool coolingActive, bool defrostActive, bool compressorOn, bool dripHoldActive);
    void updateCoolingState2(bool coolingActive, bool defrostActive, bool compressorOn, bool dripHoldActive);

    void setErrorActive(bool active);

    void setReclaimOrderNumber(const QString& number);
    void setCustomEmail(const QString& email);
    void setCustomerLockPin(const QString& pin);
    void setCustomerAutoLockEnabled(bool enabled);

    void setForcedSensors(bool en);
    void setForcedTemp1(double v);
    void setForcedTemp2(double v);
    void setForcedTemp3(double v);
    void setForcedTemp4(double v);
    void setForcedTemp5(double v);

    void setSensor1Id(const QString& id);
    void setSensor2Id(const QString& id);
    void setSensor3Id(const QString& id);
    void setSensor4Id(const QString& id);
    void setSensor5Id(const QString& id);
    void setSensor6Id(const QString& id);

    void setSensor1Offset(double off);
    void setSensor2Offset(double off);
    void setSensor3Offset(double off);
    void setSensor4Offset(double off);
    void setSensor5Offset(double off);
    void setSensor6Offset(double off);

    Q_INVOKABLE void refreshVisibleOneWireIds();

    void updateVisibleOneWireIds(const QStringList& ids);

    void setPower1On(bool on);
    void setPower2On(bool on);

    void setBath1Enabled(bool en);
    void setBath2Enabled(bool en);

    // Auto defrost schedule (settings page)
    void setAutoDefrostEnabled(bool en);
    void setAutoDefrostTime1Min(int minutes);
    void setAutoDefrostTime2Min(int minutes);

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
    void appLanguageChanged();
    void wifiLastMessageChanged();
    void wifiConnectedChanged();
    void ethernetConnectedChanged();
    void wifiAuthFailureChanged();

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

    void bath1EnabledChanged();
    void bath2EnabledChanged();

    void autoDefrostEnabledChanged();
    void autoDefrostTimeChanged();

    void reclaimInfoChanged();
    void customerScreenLockChanged();
    void customerLockConfigChanged();
    void serviceModeEnabledChanged();

    // forced sensors
    void forcedSensorsChanged();
    void forcedTempsChanged();

    // requesty do SensorWorkeru
    void requestForcedEnabled(bool en);
    void requestForcedTemps(double t1, double t2, double t3, double t4, double t5);

    void sensorConfigChanged();
    void visibleOneWireIdsChanged();

    void requestSetSensor1Id(const QString& id);
    void requestSetSensor2Id(const QString& id);
    void requestSetSensor3Id(const QString& id);
    void requestSetSensor4Id(const QString& id);
    void requestSetSensor5Id(const QString& id);
    void requestSetSensor6Id(const QString& id);

    void requestSetSensor1Offset(double off);
    void requestSetSensor2Offset(double off);
    void requestSetSensor3Offset(double off);
    void requestSetSensor4Offset(double off);
    void requestSetSensor5Offset(double off);
    void requestSetSensor6Offset(double off);

    void requestRefreshVisibleOneWireIds();

    // power worker zatim neexistuje
    void requestPower1(bool on);
    void requestPower2(bool on);

    // requests to CoolingWorker(s)
    void requestBath1Enabled(bool en);
    void requestBath2Enabled(bool en);

    void requestAutoDefrostEnabled(bool en);
    void requestAutoDefrostTimes(int t1Min, int t2Min);

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

    double targetTemp_ = 3.0;
    double targetTemp2_ = 3.0;

    int swType_ = 3;
    QString appLanguage_ = QStringLiteral("cs");
    QString wifiLastMessage_;
    bool wifiConnected_ = false;
    bool ethernetConnected_ = false;
    bool wifiAuthFailure_ = false;

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
    double forcedT4_ = -7.0;
    double forcedT5_ = 28.0;

    // Auto defrost schedule (cached)
    bool autoDefrostEnabled_ = true;
    int autoDefrostTime1Min_ = 6 * 60;
    int autoDefrostTime2Min_ = 20 * 60;

    bool power1On_ = false;
    bool power2On_ = false;

    bool bath1Enabled_ = true;
    bool bath2Enabled_ = true;
    bool customerScreenLocked_ = false;
    bool customerAutoLockEnabled_ = false;
    QString customerLockPin_ = QStringLiteral("1234");
    bool serviceModeEnabled_ = false;

    QStringList visibleOneWireIds_;

    static constexpr int mqtt_push_time = AppConfig::MQTT_POLL_INTERVAL_MS;
    QTimer* mqttTimer_ = nullptr;  // nový timer na MQTT payload

    LogManager logManager_;
    void initLogManager();
    void setWifiLastMessage(const QString& msg);
    void setWifiConnected(bool connected);
    void setEthernetConnected(bool connected);
    void setWifiAuthFailure(bool failed);
    void refreshNetworkLinkState();
    void onWifiMonitorTick();

    QTimer* wifiMonitorTimer_ = nullptr;
    QDateTime autoReconnectSuppressedUntil_;

    QString buildTempsSnapshotLine() const;
};
