#include "MqttWorker.hpp"

#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QMqttClient>
#include <QSslCertificate>
#include <QSslConfiguration>
#include <QTimer>

MqttWorker::MqttWorker(QObject* parent) : QObject(parent) {}

MqttWorker::~MqttWorker() {
    if (timer_) {
        timer_->stop();
    }

    if (mqtt_) {
        mqtt_->disconnectFromHost();
        mqtt_->deleteLater();
        mqtt_ = nullptr;
    }
}

void MqttWorker::ensureClient() {
    if (mqtt_) return;

    mqtt_ = new QMqttClient(this);
    mqtt_->setHostname(brokerHost_);
    mqtt_->setPort(brokerPort_);
    mqtt_->setUsername(brokerUser_);
    mqtt_->setPassword(brokerPass_);
    mqtt_->setCleanSession(true);
    mqtt_->setKeepAlive(15);

    // TLS config – podle původního Backend::Backend
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

    connect(mqtt_, &QMqttClient::stateChanged, this, &MqttWorker::onStateChanged);
    connect(mqtt_, &QMqttClient::errorChanged, this, &MqttWorker::onErrorChanged);
}

void MqttWorker::start() {
    // lazy vytvoření klienta
    ensureClient();

    // společný 20 s timer pro reconnect i odesílání
    if (!timer_) {
        timer_ = new QTimer(this);
        timer_->setInterval(intervalMs_);
        connect(timer_, &QTimer::timeout, this, &MqttWorker::onTimer);
    }
    if (!timer_->isActive()) timer_->start();

    if (mqtt_->state() == QMqttClient::Disconnected) {
        qInfo().noquote() << "[MQTT] Connecting (TLS) to" << brokerHost_ << ":" << brokerPort_ << "…";
        mqtt_->connectToHostEncrypted();
    }
}

void MqttWorker::stop() {
    if (timer_ && timer_->isActive()) timer_->stop();

    if (mqtt_) {
        mqtt_->disconnectFromHost();
    }
}

void MqttWorker::publish(const QByteArray& payload) {
    // jen zařadíme do fronty – vlastní odeslání řeší onTimer()
    buffer_.enqueue(payload);
    qInfo().noquote() << "[MQTT] Enqueued payload, queue size =" << buffer_.size();
}

void MqttWorker::onStateChanged(int s) {
    const auto st = static_cast<QMqttClient::ClientState>(s);
    bool connected = (st == QMqttClient::Connected);
    emit connectedChanged(connected);
    emit heartbeat("mqtt");

    qInfo() << "[MQTT] state changed:" << st;

    // Po úspěšném připojení se pokusíme frontu hned vyprázdnit
    if (connected) {
        if (!buffer_.isEmpty()) {
            qInfo() << "[MQTT] Connected, flushing queued messages:" << buffer_.size();
            flushQueueNow();
        }
    }
}

void MqttWorker::onErrorChanged() {
    if (!mqtt_) return;
    qWarning() << "[MQTT] error:" << mqtt_->error();
    emit errorOccured(QString("MQTT error %1").arg(mqtt_->error()));
}

void MqttWorker::onTimer() {
    // pravidelný heartbeat – watchdog očekává aktivitu jednou za ~20 s
    emit heartbeat("mqtt");

    if (!mqtt_) {
        // nemáme klienta – zkusíme ho vytvořit a připojit
        ensureClient();
    }

    if (mqtt_->state() != QMqttClient::Connected) {
        // nejsme připojeni → periodicky se snažíme znovu připojit
        qInfo() << "[MQTT] Not connected, trying reconnect…";
        mqtt_->connectToHostEncrypted();
        return;
    }

    // Připojeno – zkusíme poslat jednu zprávu z fronty
    if (buffer_.isEmpty()) {
        qDebug() << "[MQTT] Timer tick, nothing to send.";
        return;
    }

    const QByteArray payload = buffer_.head();
    auto result = mqtt_->publish(topic_, payload, 1 /*QoS*/, false /*retain*/);
    if (result == -1) {
        qWarning() << "[MQTT] Publish failed, will retry later.";
        // necháme payload ve frontě, příště to zkusíme znovu
        // pro jistotu se odpojíme – reconnect se postará onTimer()
        mqtt_->disconnectFromHost();
    } else {
        buffer_.dequeue();
        qInfo().noquote() << "[MQTT] Published to" << topic_ << ":" << payload;
    }
}

void MqttWorker::flushQueueNow() {
    if (!mqtt_ || mqtt_->state() != QMqttClient::Connected) return;

    while (!buffer_.isEmpty()) {
        const QByteArray payload = buffer_.head();
        auto result = mqtt_->publish(topic_, payload, 1 /*QoS*/, false /*retain*/);
        if (result == -1) {
            qWarning() << "[MQTT] Publish failed during flush, will retry later.";
            // neodebíráme z fronty, příští pokus to zkusí znovu
            mqtt_->disconnectFromHost();
            break;
        } else {
            buffer_.dequeue();
            qInfo().noquote() << "[MQTT] Flushed queued payload to" << topic_ << ":" << payload;
            emit heartbeat("mqtt");
        }
    }
}
