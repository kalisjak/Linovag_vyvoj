#include "MqttWorker.hpp"

#include <QMqttClient>
#include <QFile>
#include <QSslConfiguration>
#include <QSslCertificate>
#include <QDateTime>
#include <QDebug>

MqttWorker::MqttWorker(QObject* parent)
    : QObject(parent)
{
}

MqttWorker::~MqttWorker()
{
    if (mqtt_) {
        mqtt_->disconnectFromHost();
        mqtt_->deleteLater();
    }
}

void MqttWorker::start()
{
    if (mqtt_)
        return;

    mqtt_ = new QMqttClient(this);
    mqtt_->setHostname(brokerHost_);
    mqtt_->setPort(brokerPort_);
    mqtt_->setUsername(brokerUser_);
    mqtt_->setPassword(brokerPass_);
    mqtt_->setCleanSession(true);
    mqtt_->setKeepAlive(15);

    // TLS config – 1:1 z tvého Backend::Backend
    QSslConfiguration ssl = QSslConfiguration::defaultConfiguration();
    QFile caFile(ca_file_);
    if (!caFile.open(QIODevice::ReadOnly)) {
        qWarning() << "Nemůžu otevřít CA soubor:" << caFile.errorString();
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

    qInfo().noquote() << "[MQTT] Connecting (TLS) to" << brokerHost_ << ":" << brokerPort_ << "…";
    mqtt_->connectToHostEncrypted();
}

void MqttWorker::stop()
{
    if (mqtt_)
        mqtt_->disconnectFromHost();
}

void MqttWorker::onStateChanged(int s)
{
    const auto st = static_cast<QMqttClient::ClientState>(s);
    bool connected = (st == QMqttClient::Connected);
    emit connectedChanged(connected);
    emit heartbeat("mqtt");

    qInfo() << "[MQTT] state:" << st;
}

void MqttWorker::onErrorChanged()
{
    if (!mqtt_) return;
    qWarning() << "[MQTT] error:" << mqtt_->error();
    emit errorOccured(QString("MQTT error %1").arg(mqtt_->error()));
}

void MqttWorker::publish(const QByteArray& payload)
{
    if (!mqtt_ || mqtt_->state() != QMqttClient::Connected) {
        qWarning() << "[MQTT] Not connected – cannot publish";
        return;
    }

    auto result = mqtt_->publish(topic_, payload, 1 /*QoS*/, false /*retain*/);
    if (result == -1) {
        qWarning() << "[MQTT] Publish failed";
    } else {
        qInfo().noquote() << "[MQTT] Published to" << topic_ << ":" << payload;
        emit heartbeat("mqtt");
    }
}
