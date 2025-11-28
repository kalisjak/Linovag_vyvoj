#include "backend.hpp"

#include <QDebug>
#include <QDateTime>
#include <QTimer>
#include <QFile>
#include <QSslConfiguration>
#include <QSslCertificate>
// #include <QMqttClient>  // ponecháno kvůli kompatibilitě s headerem, i když ho tady už nepoužíváme

Backend::Backend(QObject* parent)
    : QObject(parent),
      rng_(std::random_device{}())
{
    // V nové architektuře zde už nespouštíme žádné timery ani MQTT.
    // Všechny „aktivní“ věci (senzory, MQTT, watchdog) běží ve workerech v jiných threadech.
}

// --- Slot pro změnu požadované teploty z QML -------------------------------

void Backend::setTargetTemp(double t)
{
    if (targetTemp_ == t)
        return;

    targetTemp_ = t;
    qInfo() << "[Backend] Target temperature set to" << targetTemp_ << "°C";
    emit targetTempChanged();
}

// --- Sloty volané z worker vláken -----------------------------------------

void Backend::onSensorValues(double v1, double v2)
{
    if (value1_ != v1) {
        value1_ = v1;
        emit value1Changed();
    }

    if (value2_ != v2) {
        value2_ = v2;
        emit value2Changed();
    }
}

void Backend::onMqttConnectedChanged(bool ok)
{
    if (mqttConnected_ == ok)
        return;

    mqttConnected_ = ok;
    emit mqttConnectedChanged();
}

// --- Odesílání MQTT zpráv (přes MqttWorker) --------------------------------

void Backend::sendMessage(const QString& msg)
{
    bool ok = false;
    const double temp = msg.toDouble(&ok);
    if (!ok) {
        qWarning() << "[Backend] sendMessage: invalid temperature value:" << msg;
        return;
    }

    // časová značka v UTC
    const QString ts = QDateTime::currentDateTimeUtc().toString(Qt::ISODate) + "Z";

    // jednoduchý JSON payload – uprav si klidně podle finálního schématu
    const QString payloadStr = QString::fromLatin1(
        "{"
          "\"ts\":\"%1\","
          "\"schema\":\"v1\","
          "\"data\":{"
            "\"temp\":%2,"
            "\"ok\":1,"
            "\"status\":\"online\""
          "}"
        "}"
    ).arg(ts).arg(temp, 0, 'f', 2);

    const QByteArray payload = payloadStr.toUtf8();

    qInfo().noquote() << "[Backend] Prepared payload:" << payload;

    // Reálné odeslání necháváme na MqttWorkeru v jiném vlákně
    emit publishMqtt(payload);
}

// --- Pomocné metody / stuby pro kompatibilitu s původním headerem ---------
// Pokud je v backend.hpp pořád deklarovaná funkce readDS18B20, updateValues
// nebo sloty onMqttStateChanged/onMqttErrorChanged, musí zde existovat
// i jejich definice, jinak linker hlásí „undefined reference“.

// double Backend::readDS18B20(std::string& deviceId)
// {
//     Q_UNUSED(deviceId);
//     // Reálné čtení už dělá SensorWorker v jiném vlákně.
//     // Tohle tu zůstává jen jako „dummy“, aby seděl podpis z headeru.
//     return 0.0;
// }

QString Backend::serialNumber() const
{
    // Původní chování necháváme stejné
    return QStringLiteral("SN-65468");
}

// void Backend::updateValues()
// {
//     // V nové architektuře hodnoty aktualizuje SensorWorker → onSensorValues().
//     // Tady už se nic neděje, metoda je jen kvůli kompatibilitě s původním headerem.
// }

// void Backend::onMqttStateChanged(int s)
// {
//     Q_UNUSED(s);
//     // Stav MQTT nyní řeší MqttWorker a výsledný stav nám předává přes onMqttConnectedChanged().
// }

// void Backend::onMqttErrorChanged()
// {
//     // Chyby MQTT řeší MqttWorker – sem se už nic neposílá.
// }
