#pragma once

#include <QObject>
#include <QQueue>
#include <QByteArray>
#include <QString>

#include "config.hpp"

class QMqttClient;

class MqttWorker : public QObject {
    Q_OBJECT
public:
    explicit MqttWorker(QObject* parent = nullptr);
    ~MqttWorker() override;

signals:
    void connectedChanged(bool ok);
    void heartbeat(const QString& name);
    void errorOccured(const QString& msg);

public slots:
    void start();                  // volá se po startu threadu
    void stop();                   // korektní ukončení
    void publish(const QByteArray& data);   // backend → přidá do fronty a případně flushne

private slots:
    void onStateChanged(int state);    // připojeno/odpojeno
    void onErrorChanged();
    void onDisconnected();

private:
    void ensureClient();
    void ensureConnected();
    void flush();                  // vyprázdní frontu, pokud jsme connected

    QMqttClient* mqtt_ = nullptr;
    QQueue<QByteArray> buffer_;

    // konfigurace brokeru – centralizovaná v AppConfig
    const QString brokerHost_ = AppConfig::MQTT_BROKER_HOST;
    const quint16 brokerPort_ = AppConfig::MQTT_BROKER_PORT;
    const QString brokerUser_ = AppConfig::MQTT_USERNAME;
    const QString brokerPass_ = AppConfig::MQTT_PASSWORD;
    const QString topic_      = AppConfig::MQTT_TOPIC_TELEMETRY;
    const QString ca_file_    = AppConfig::MQTT_CA_FILE;

};
