#include "runtimeConfig.hpp"

#include <QSettings>

static constexpr const char* CONFIG_PATH = "/etc/lnvg/lnvg.conf";

namespace RuntimeConfig {

static QSettings makeSettings() {
    return QSettings(QString::fromUtf8(CONFIG_PATH), QSettings::IniFormat);
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
void setSensor6Id(const QString& id) { setId("sensors/sensor6_id", id); }

// ===== Auto defrost schedule =====
bool autoDefrostEnabled() {
    QSettings s = makeSettings();
    return s.value("defrost/auto_enabled", true).toBool();
}

void setAutoDefrostEnabled(bool en) {
    QSettings s = makeSettings();
    s.setValue("defrost/auto_enabled", en);
}

static int clampDayMin(int m) {
    // normalize to 0..1439
    m %= 1440;
    if (m < 0) m += 1440;
    return m;
}

int autoDefrostTime1Min() {
    QSettings s = makeSettings();
    return clampDayMin(s.value("defrost/auto_time1_min", 6 * 60).toInt());
}

void setAutoDefrostTime1Min(int minutes) {
    QSettings s = makeSettings();
    s.setValue("defrost/auto_time1_min", clampDayMin(minutes));
}

int autoDefrostTime2Min() {
    QSettings s = makeSettings();
    return clampDayMin(s.value("defrost/auto_time2_min", 20 * 60).toInt());
}

void setAutoDefrostTime2Min(int minutes) {
    QSettings s = makeSettings();
    s.setValue("defrost/auto_time2_min", clampDayMin(minutes));
}

// ===== Sensor offsets (°C) =====
static double getOffset(const char* key, double def) {
    QSettings s = makeSettings();
    return s.value(key, def).toDouble();
}
static void setOffset(const char* key, double val) {
    QSettings s = makeSettings();
    s.setValue(key, val);
}

double sensor1Offset() { return getOffset("sensors/sensor1_offset", 0.0); }
void setSensor1Offset(double off) { setOffset("sensors/sensor1_offset", off); }

double sensor2Offset() { return getOffset("sensors/sensor2_offset", 0.0); }
void setSensor2Offset(double off) { setOffset("sensors/sensor2_offset", off); }

double sensor3Offset() { return getOffset("sensors/sensor3_offset", 0.0); }
void setSensor3Offset(double off) { setOffset("sensors/sensor3_offset", off); }

double sensor4Offset() { return getOffset("sensors/sensor4_offset", 0.0); }
void setSensor4Offset(double off) { setOffset("sensors/sensor4_offset", off); }

double sensor5Offset() { return getOffset("sensors/sensor5_offset", 0.0); }
void setSensor5Offset(double off) { setOffset("sensors/sensor5_offset", off); }

double sensor6Offset() { return getOffset("sensors/sensor6_offset", 0.0); }
void setSensor6Offset(double off) { setOffset("sensors/sensor6_offset", off); }

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

QString appLanguage() {
    QSettings s = makeSettings();
    return s.value("app/language", QStringLiteral("cs")).toString();
}

void setAppLanguage(const QString& lang) {
    QSettings s = makeSettings();
    s.setValue("app/language", lang);
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
