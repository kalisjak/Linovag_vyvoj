#pragma once
#include <QObject>

class QMqttClient;

class MqttWorker : public QObject {
    Q_OBJECT
public:
    explicit MqttWorker(QObject* parent = nullptr);
    ~MqttWorker();

signals:
    void heartbeat(const QString& name);
    void connectedChanged(bool ok);         // do Backend
    void errorOccured(const QString& msg);  // volitelné, do logů/GUI

public slots:
    void start();   // naváže spojení
    void stop();    // odpojí se
    void publish(const QByteArray& payload); // požadavek od Backend

private slots:
    void onStateChanged(int s);
    void onErrorChanged();

private:
    QMqttClient* mqtt_ = nullptr;

    const QString brokerHost_ = "192.168.3.101";
    const quint16 brokerPort_ = 8883;
    const QString brokerUser_ = "device1";
    const QString brokerPass_ = "pass1";
    const QString topic_      = "devices/device1/telemetry";
    const QString ca_file_    = "/usr/local/share/ca-certificates/rootCA.pem";
};
