#pragma once

#include <QObject>
#include <QQueue>
#include <QByteArray>
#include <QString>

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
    void onStateChanged(int s);    // připojeno/odpojeno
    void onErrorChanged();
    void onDisconnected();

private:
    void ensureClient();
    void ensureConnected();
    void flush();                  // vyprázdní frontu, pokud jsme connected

    QMqttClient* mqtt_ = nullptr;
    QQueue<QByteArray> buffer_;

    // konfigurace brokeru – uprav podle sebe, pokud máš jiné hodnoty
    const QString brokerHost_ = QStringLiteral("192.168.3.101");
    const quint16 brokerPort_ = 8883;
    const QString brokerUser_ = QStringLiteral("device1");
    const QString brokerPass_ = QStringLiteral("pass1");
    const QString topic_      = QStringLiteral("devices/device1/telemetry");
    const QString ca_file_    = QStringLiteral("/usr/local/share/ca-certificates/rootCA.pem");
};
