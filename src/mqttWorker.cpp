#include "mqttWorker.hpp"

#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QMqttClient>
#include <QSslCertificate>
#include <QSslConfiguration>

MqttWorker::MqttWorker(QObject* parent)
    : QObject(parent)
{
}

MqttWorker::~MqttWorker()
{
    if (mqtt_) {
        mqtt_->disconnectFromHost();
        // parent = this → smaže se automaticky
    }
}

void MqttWorker::start()
{
    ensureClient();
    ensureConnected();
}

void MqttWorker::stop()
{
    if (mqtt_) {
        mqtt_->disconnectFromHost();
    }
}

void MqttWorker::ensureClient()
{
    if (mqtt_) return;

    mqtt_ = new QMqttClient(this);
    mqtt_->setHostname(brokerHost_);
    mqtt_->setPort(brokerPort_);
    mqtt_->setUsername(brokerUser_);
    mqtt_->setPassword(brokerPass_);
    mqtt_->setCleanSession(true);
    mqtt_->setKeepAlive(15);

    // TLS config – podle tvého původního kódu
    QSslConfiguration ssl = QSslConfiguration::defaultConfiguration();
    QFile caFile(ca_file_);
    if (!caFile.open(QIODevice::ReadOnly)) {
        qWarning() << "[MQTT] Nemůžu otevřít CA soubor:" << ca_file_ << caFile.errorString();
    } else {
        QList<QSslCertificate> caList = ssl.caCertificates();
        caList.append(QSslCertificate::fromDevice(&caFile, QSsl::Pem));
        ssl.setCaCertificates(caList);
        QSslConfiguration::setDefaultConfiguration(ssl);
    }

    connect(mqtt_, &QMqttClient::stateChanged,
            this, &MqttWorker::onStateChanged);
    connect(mqtt_, &QMqttClient::errorChanged,
            this, &MqttWorker::onErrorChanged);
    connect(mqtt_, &QMqttClient::disconnected,
            this, &MqttWorker::onDisconnected);
}

void MqttWorker::ensureConnected()
{
    ensureClient();

    if (mqtt_->state() == QMqttClient::Disconnected) {
        qInfo().noquote() << "[MQTT] Connecting (TLS) to"
                          << brokerHost_ << ":" << brokerPort_ << "…";
        mqtt_->connectToHostEncrypted();
    }
}

void MqttWorker::publish(const QByteArray& data)
{
    // 1) přidáme do fronty
    buffer_.enqueue(data);
    qInfo().noquote() << "[MQTT] Enqueued payload, queue size =" << buffer_.size();
    
    emit heartbeat(QStringLiteral("mqtt"));
    // 2) zajistit klienta + případně připojení
    ensureConnected();
    
    // 3) pokud nejsme connected, NEŠAHÁME na frontu
    if (!mqtt_ || mqtt_->state() != QMqttClient::Connected) {
        qInfo() << "[MQTT] Not connected, will send when connected. Queue size =" << buffer_.size();
        return;
    }
    
    // 4) jsme connected → zkusíme vyprázdnit frontu
    flush();
}

void MqttWorker::onStateChanged(int state)
{
    const auto st = static_cast<QMqttClient::ClientState>(state);
    const bool connected = (st == QMqttClient::Connected);

    emit connectedChanged(connected);
    emit heartbeat(QStringLiteral("mqtt"));

    qInfo() << "[MQTT] state changed:" << st << "queue size =" << buffer_.size();

    // Po úspěšném připojení zkusíme frontu hned vyprázdnit
    if (connected) {
        flush();
    }
}

void MqttWorker::onDisconnected()
{
    emit connectedChanged(false);
    qWarning() << "[MQTT] Disconnected. Queue size =" << buffer_.size();
}

void MqttWorker::onErrorChanged()
{
    if (!mqtt_) return;
    qWarning() << "[MQTT] error:" << mqtt_->error();
    emit heartbeat(QStringLiteral("mqtt"));
    emit errorOccured(QStringLiteral("MQTT error %1").arg(mqtt_->error()));
}

void MqttWorker::flush()
{
    if (!mqtt_ || mqtt_->state() != QMqttClient::Connected) {
        qDebug() << "[MQTT] flush(): not connected, queue size =" << buffer_.size();
        emit heartbeat(QStringLiteral("mqtt"));
        return;
    }

    while (!buffer_.isEmpty()) {
        const QByteArray payload = buffer_.head();
        qInfo().noquote() << "[MQTT] flush(): trying publish to" << topic_ << ":" << payload;

        const auto result = mqtt_->publish(topic_, payload, 1 /*QoS*/, false /*retain*/);
        if (result == -1) {
            // NEODEBÍRÁME Z FRONTY
            qWarning() << "[MQTT] flush(): publish failed, keeping in queue. Queue size =" << buffer_.size();
            // necháme připojení jak je, příští pokus flush() to zkusí znovu
            break;
        }

        buffer_.dequeue();
        qInfo().noquote() << "[MQTT] flush(): published OK, remaining queue size =" << buffer_.size();
        emit heartbeat(QStringLiteral("mqtt"));
    }
}
