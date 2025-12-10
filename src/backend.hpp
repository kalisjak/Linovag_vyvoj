#pragma once
#include <QObject>
#include <random>
#include <fstream>
#include <string>
#include <QtGlobal>
#include <QString>
#include <QStringList>
#include <QByteArray>

QT_BEGIN_NAMESPACE
class QTimer;
QT_END_NAMESPACE

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(double value1 READ value1 NOTIFY value1Changed)
    Q_PROPERTY(double value2 READ value2 NOTIFY value2Changed)
    Q_PROPERTY(bool   mqttConnected READ mqttConnected NOTIFY mqttConnectedChanged)
    Q_PROPERTY(QString serialNumber READ serialNumber NOTIFY serialNumberChanged)
    Q_PROPERTY(double targetTemp READ targetTemp WRITE setTargetTemp NOTIFY targetTempChanged)
    Q_PROPERTY(QStringList historyLog READ historyLog NOTIFY historyLogChanged)

    Q_PROPERTY(bool   errorActive        READ errorActive        NOTIFY errorActiveChanged)
    Q_PROPERTY(bool   coolingActive      READ coolingActive      NOTIFY coolingActiveChanged)
    Q_PROPERTY(bool   defrostActive      READ defrostActive      NOTIFY defrostActiveChanged)
    Q_PROPERTY(bool   compressorOn       READ compressorOn       NOTIFY compressorOnChanged)

    Q_PROPERTY(QString reclaimOrderNumber READ reclaimOrderNumber NOTIFY reclaimInfoChanged)
    Q_PROPERTY(QString reclaimEmail       READ reclaimEmail       NOTIFY reclaimInfoChanged)

public:
    explicit Backend(QObject* parent = nullptr);

    double value1() const { return value1_; }
    double value2() const { return value2_; }
    double targetTemp() const { return targetTemp_; }
    bool   mqttConnected() const { return mqttConnected_; }
    QString serialNumber() const;
    QStringList historyLog() const { return historyLog_; }

    bool errorActive()   const { return errorActive_; }
    bool coolingActive() const { return coolingActive_; }
    bool defrostActive() const { return defrostActive_; }
    bool compressorOn()  const { return compressorOn_; }

    QString reclaimOrderNumber() const;
    QString reclaimEmail() const;

    Q_INVOKABLE void sendMessage(const QString& msg);

public slots:
    void setTargetTemp(double t);
     void onMqttTimerTick();

    // sloty, které budou volat worker vlákna:
    void onSensorValues(double v1, double v2);
    void onMqttConnectedChanged(bool ok);

    void updateCoolingState(bool coolingActive,
                            bool defrostActive,
                            bool compressorOn);

    void setErrorActive(bool active); // pro pozdější použití odjinud

    void setReclaimOrderNumber(const QString& number);
    void setReclaimEmail(const QString& email);

signals:
    void value1Changed();
    void value2Changed();
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

private:
    double value1_ = 0.0;
    double value2_ = 0.0;
    double targetTemp_ = 5.0;
    std::mt19937 rng_;
    bool   mqttConnected_ = false;
    bool errorActive_   = false;
    bool coolingActive_ = false;
    bool defrostActive_ = false;
    bool compressorOn_  = false;

    QTimer* mqttTimer_ = nullptr;   // nový timer na MQTT payload

    QStringList historyLog_;
    QString logsDirPath_;
    QString currentLogFilePath_;
    int currentLogIndex_ = 0;


    static constexpr int kMaxHistoryLines = 500;
    static constexpr int kMaxLogFiles = 30;
    static constexpr long long kMaxLogFileSizeBytes = 200 * 1024; // 200 kB

    void initLogs();
    void appendLogLine(const QString& line);
    void rotateLogFileIfNeeded();
    void cleanupOldLogFiles();
    QStringList loadLastLines(const QString& filePath, int maxLines) const;
};
