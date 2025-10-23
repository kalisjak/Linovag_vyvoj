#include "backend.hpp"

#include <QTimer>
#include <QDebug>
#include <QtMqtt/QMqttClient>



Backend::Backend(QObject* parent)
    : QObject(parent),
      rng_(std::random_device{}())
{
    // demo timer
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &Backend::updateValues);
    timer_->start(5000);
    updateValues();

    // MQTT client
    mqtt_ = new QMqttClient(this);
    mqtt_->setHostname(brokerHost_);
    mqtt_->setPort(brokerPort_);
    mqtt_->setUsername(brokerUser_);
    mqtt_->setPassword(brokerPass_);
    mqtt_->setCleanSession(true);
    mqtt_->setKeepAlive(15);

    connect(mqtt_, &QMqttClient::stateChanged, this, &Backend::onMqttStateChanged);
    connect(mqtt_, &QMqttClient::errorChanged, this, &Backend::onMqttErrorChanged);

    qInfo().noquote() << "[MQTT] Connecting to" << brokerHost_ << ":" << brokerPort_ << "…";
    mqtt_->connectToHost();
}

void Backend::onMqttStateChanged(int s)
{
    const auto st = static_cast<QMqttClient::ClientState>(s);
    bool connected = (st == QMqttClient::Connected);
    if (connected != mqttConnected_) {
        mqttConnected_ = connected;
        emit mqttConnectedChanged();
    }
    qInfo() << "[MQTT] state:" << st;
}

void Backend::onMqttErrorChanged()
{
    qWarning() << "[MQTT] error:" << mqtt_->error();
    // qWarning() << "[MQTT] error:" << mqtt_->error() << mqtt_->errorString();
}

void Backend::sendMessage(const QString& msg)
{
    // očekáváme číslo – např. "3.14"
    bool ok = false;
    const double temp = msg.toDouble(&ok);
    if (!ok) {
        qWarning() << "[MQTT] Invalid temp value:" << msg;
        return;
    }

    if (mqtt_->state() != QMqttClient::Connected) {
        qWarning() << "[MQTT] Not connected – cannot publish";
        return;
    }

    // jednoduchý JSON payload (přidej další pole dle potřeby)
    const QString payload = QString("{\"temp\":%1,\"rpm\":12.34,\"ok\":true}")
                                .arg(temp, 0, 'f', 2);

    auto result = mqtt_->publish(topic_, payload.toUtf8(), 1 /*QoS*/, false /*retain*/);
    if (result == -1) {
        qWarning() << "[MQTT] Publish failed";
    } else {
        qInfo().noquote() << "[MQTT] Published to" << topic_ << ":" << payload;
    }
}

double Backend::readDS18B20( std::string& deviceId)
{
    std::string path = "/sys/bus/w1/devices/" + deviceId + "/w1_slave";
    std::ifstream file(path);
    if (!file.is_open()) return -999.0;

    std::string line;
    std::getline(file, line); // první řádek
    if (line.find("YES") == std::string::npos) return -999.0;
    std::getline(file, line); // druhý řádek
    auto pos = line.find("t=");
    if (pos == std::string::npos) return -999.0;

    int temp_milli = std::stoi(line.substr(pos + 2));
    return temp_milli / 1000.0;
}

QString Backend::serialNumber() const { return "SN-65468"; }

void Backend::updateValues()
{
    value1_ = readDS18B20(s1);
    value2_ = readDS18B20(s2);
    emit value1Changed();
    emit value2Changed();
}
