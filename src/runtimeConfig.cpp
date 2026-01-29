#include "runtimeConfig.hpp"

#include <QSettings>

// Linux ubuntu: ~/.config/gastroConf/lnvg_app.conf
// Linux rpi: /root/.config/gastroConf/lnvg_app.conf
static constexpr const char* ORG_NAME = "gastroConf";
static constexpr const char* APP_NAME = "lnvg_app";

namespace RuntimeConfig {

static QSettings makeSettings() {
    return QSettings(ORG_NAME, APP_NAME);
}

// ===== Device serial =====

QString deviceSerial() {
    QSettings s = makeSettings();
    return s.value("device/serial", QStringLiteral("SN-65468")).toString();
}

void setDeviceSerial(const QString& serial) {
    QSettings s = makeSettings();
    s.setValue("device/serial", serial);
}

// ===== Software type =====
int softwareType() {
    QSettings s = makeSettings();
    return s.value("device/software_type", 3).toInt();
}
void setSoftwareType(int type) {
    QSettings s = makeSettings();
    s.setValue("device/software_type", type);
}

// ===== Sensor IDs =====
// "28-0b24409ff61f"
std::string sensor1Id() { return getId("sensors/sensor1_id", "28-000000000000"); }
void setSensor1Id(const QString& id) { setId("sensors/sensor1_id", id); }

// "28-0b2440f86631"
std::string sensor2Id() { return getId("sensors/sensor2_id", "28-000000000000"); }
void setSensor2Id(const QString& id) { setId("sensors/sensor2_id", id); }

// "28-0b2440323b08"
std::string sensor3Id() { return getId("sensors/sensor3_id", "28-000000000000"); }
void setSensor3Id(const QString& id) { setId("sensors/sensor3_id", id); }

std::string sensor4Id() { return getId("sensors/sensor4_id", "28-000000000000"); }
void setSensor4Id(const QString& id) { setId("sensors/sensor4_id", id); }

std::string sensor5Id() { return getId("sensors/sensor5_id", "28-000000000000"); }
void setSensor5Id(const QString& id) { setId("sensors/sensor5_id", id); }

// DHT22 sensor ID (může být DS18B20 pro simulaci)
std::string sensor6Id() { return getId("sensors/sensor6_id", "28-000000000000"); }

// ===== Reclaim order number and email =====
QString reclaimOrderNumber() {
    QSettings s = makeSettings();
    // např. [reclaim] order_number = "xx-123456-abcd"
    return s.value("reclaim/order_number", "xx-123456-abcd").toString();
}

void setReclaimOrderNumber(const QString& number) {
    QSettings s = makeSettings();
    s.setValue("reclaim/order_number", number);
}

QString reclaimEmail() {
    QSettings s = makeSettings();
    return s.value("reclaim/email", "reklamace@gastro.cz").toString();
}

void setReclaimEmail(const QString& email) {
    QSettings s = makeSettings();
    s.setValue("reclaim/email", email);
}

static std::string getId(const char* key, const char* def) {
    QSettings s = makeSettings();
    const QString id = s.value(key, QString::fromUtf8(def)).toString();
    return id.toStdString();
}

static void setId(const char* key, const QString& id) {
    QSettings s = makeSettings();
    s.setValue(key, id);
}
}  // namespace RuntimeConfig
