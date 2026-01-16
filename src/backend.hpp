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

QT_BEGIN_NAMESPACE
class QTimer;
QT_END_NAMESPACE

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(double value1 READ value1 NOTIFY value1Changed)
    Q_PROPERTY(double value2 READ value2 NOTIFY value2Changed)
    Q_PROPERTY(double value3 READ value3 NOTIFY value3Changed)
    Q_PROPERTY(bool mqttConnected READ mqttConnected NOTIFY mqttConnectedChanged)
    Q_PROPERTY(QString serialNumber READ serialNumber NOTIFY serialNumberChanged)
    Q_PROPERTY(double targetTemp READ targetTemp WRITE setTargetTemp NOTIFY targetTempChanged)
    Q_PROPERTY(QStringList historyLog READ historyLog NOTIFY historyLogChanged)

    Q_PROPERTY(bool errorActive READ errorActive NOTIFY errorActiveChanged)
    Q_PROPERTY(bool coolingActive READ coolingActive NOTIFY coolingActiveChanged)
    Q_PROPERTY(bool defrostActive READ defrostActive NOTIFY defrostActiveChanged)
    Q_PROPERTY(bool compressorOn READ compressorOn NOTIFY compressorOnChanged)

    Q_PROPERTY(QString reclaimOrderNumber READ reclaimOrderNumber NOTIFY reclaimInfoChanged)
    Q_PROPERTY(QString reclaimEmail READ reclaimEmail NOTIFY reclaimInfoChanged)
    // forced sensors for testing
    Q_PROPERTY(bool forcedSensors READ forcedSensors WRITE setForcedSensors NOTIFY forcedSensorsChanged)
    Q_PROPERTY(double forcedTemp1 READ forcedTemp1 WRITE setForcedTemp1 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp2 READ forcedTemp2 WRITE setForcedTemp2 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp3 READ forcedTemp3 WRITE setForcedTemp3 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp4 READ forcedTemp4 WRITE setForcedTemp4 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double forcedTemp5 READ forcedTemp5 WRITE setForcedTemp5 NOTIFY forcedTempsChanged)
    Q_PROPERTY(double value4 READ value4 NOTIFY value4Changed)
    Q_PROPERTY(double value5 READ value5 NOTIFY value5Changed)

   public:
    explicit Backend(QObject* parent = nullptr);

    double value1() const { return value1_; }
    double value2() const { return value2_; }
    double value3() const { return value3_; }
    double value4() const { return value4_; }
    double value5() const { return value5_; }

    double targetTemp() const { return targetTemp_; }
    bool mqttConnected() const { return mqttConnected_; }
    QString serialNumber() const;
    QStringList historyLog() const { return historyLog_; }

    bool errorActive() const { return errorActive_; }
    bool coolingActive() const { return coolingActive_; }
    bool defrostActive() const { return defrostActive_; }
    bool compressorOn() const { return compressorOn_; }

    QString reclaimOrderNumber() const;
    QString reclaimEmail() const;

    // forced sensors for testing
    bool forcedSensors() const { return forcedSensors_; }
    void setForcedSensors(bool en);

    double forcedTemp1() const { return forcedT1_; }
    double forcedTemp2() const { return forcedT2_; }
    double forcedTemp3() const { return forcedT3_; }
    double forcedTemp4() const { return forcedT4_; }
    double forcedTemp5() const { return forcedT5_; }

    Q_INVOKABLE void sendMessage(const QString& msg);

   public slots:
    void setTargetTemp(double t);
    void onMqttTimerTick();

    // sloty, které budou volat worker vlákna:
    void onSensorValues(double v1, double v2);
    void onMqttConnectedChanged(bool ok);

    void updateCoolingState(bool coolingActive, bool defrostActive, bool compressorOn);

    void setErrorActive(bool active);  // pro pozdější použití odjinud

    void setReclaimOrderNumber(const QString& number);
    void setReclaimEmail(const QString& email);

    // forced sensors for testing
    void setForcedTemp1(double v);
    void setForcedTemp2(double v);
    void setForcedTemp3(double v);
    void setForcedTemp4(double v);
    void setForcedTemp5(double v);

    void updateSensorValues(double v1, double v2);
    void updateEvapValue(double v3);
    void onSensorValues45(double v4, double v5);

   signals:
    void value1Changed();
    void value2Changed();
    void value3Changed();
    void value4Changed();
    void value5Changed();

    void targetTempChanged();
    void mqttConnectedChanged();
    void serialNumberChanged();
    void historyLogChanged();

    // signály směrem k workerům
    void publishMqtt(const QByteArray& payload);

    void errorActiveChanged();
    void coolingActiveChanged();
    void defrostActiveChanged();
    void compressorOnChanged();

    void reclaimInfoChanged();

    // forced sensors for testing
    void forcedSensorsChanged();
    void forcedTempsChanged();

    // requesty do SensorWorkeru (napojíš v main.cpp)
    void requestForcedEnabled(bool en);
    void requestForcedTemps(double t1, double t2, double t3, double t4, double t5);

   private:
    double value1_ = 0.0;
    double value2_ = 0.0;
    double value3_ = 0.0;
    double value4_ = -99.0;
    double value5_ = -99.0;

    double targetTemp_ = 5.0;
    std::mt19937 rng_;
    bool mqttConnected_ = false;
    bool errorActive_ = false;
    bool coolingActive_ = false;
    bool defrostActive_ = false;
    bool compressorOn_ = false;

    // forced sensors for testing
    bool forcedSensors_ = false;
    double forcedT1_ = 5.0;
    double forcedT2_ = 5.0;
    double forcedT3_ = -10.0;
    double forcedT4_ = 22.2;
    double forcedT5_ = 22.2;

    QTimer* mqttTimer_ = nullptr;  // nový timer na MQTT payload

    QStringList historyLog_;
    QString logsDirPath_;
    QString currentLogFilePath_;
    int currentLogIndex_ = 0;

    // separátní log všech teplot (T1,T2,EVAP,T4,T5)
    QString currentTempsLogFilePath_;
    int currentTempsLogIndex_ = 0;

    static constexpr int kMaxHistoryLines = AppConfig::LOG_MAX_HISTORY_LINES;
    static constexpr int kMaxLogFiles = AppConfig::LOG_MAX_FILES;
    static constexpr long long kMaxLogFileSizeBytes = AppConfig::LOG_MAX_FILE_SIZE_BYTES;  // 200 kB
    
    static constexpr int mqtt_push_time = AppConfig::MQTT_POLL_INTERVAL_MS;
    
    void initLogs();
    void initTempsLogs();
    void appendLogLine(const QString& line);
    void appendTempsLogLine(const QString& line);
    void rotateLogFileIfNeeded();
    void rotateTempsLogFileIfNeeded();
    void cleanupOldLogFiles();
    void cleanupOldTempsLogFiles();
    void appendAllTempsSnapshot();
    void updateSensorValues45(double v4, double v5);

    QStringList loadLastLines(const QString& filePath, int maxLines) const;
};
