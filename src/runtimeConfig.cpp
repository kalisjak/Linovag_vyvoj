#include "runtimeConfig.hpp"
#include <QSettings>

// Můžeš si změnit org/app názvy – ovlivní cestu config souboru
// Linux: ~/.config/kubalinovag/lnvg_app.conf
static constexpr const char* ORG_NAME = "gastroConf";
static constexpr const char* APP_NAME = "lnvg_app";

namespace RuntimeConfig {

static QSettings makeSettings()
{
    // INI ve standardním místě pro uživatele
    return QSettings(ORG_NAME, APP_NAME);
}

// ===== Device serial =====

QString deviceSerial()
{
    QSettings s = makeSettings();
    // výchozí hodnota, když v configu nic není
    return s.value("device/serial", QStringLiteral("SN-65468")).toString();
}

void setDeviceSerial(const QString& serial)
{
    QSettings s = makeSettings();
    s.setValue("device/serial", serial);
}

// ===== Sensor IDs =====

std::string sensor1Id()
{
    QSettings s = makeSettings();
    QString id = s.value("sensors/sensor1_id",
                         QStringLiteral("28-0b24409ff61f")).toString();
    return id.toStdString();
}

void setSensor1Id(const QString& id)
{
    QSettings s = makeSettings();
    s.setValue("sensors/sensor1_id", id);
}

std::string sensor2Id()
{
    QSettings s = makeSettings();
    QString id = s.value("sensors/sensor2_id",
                         QStringLiteral("28-0b2440f86631")).toString();
    return id.toStdString();
}

void setSensor2Id(const QString& id)
{
    QSettings s = makeSettings();
    s.setValue("sensors/sensor2_id", id);
}
std::string sensor3Id()
{
    QSettings s = makeSettings();
    QString id = s.value("sensors/sensor3_id",
                         QStringLiteral("28-0b2440323b08")).toString();
    return id.toStdString();
}

void setSensor3Id(const QString& id)
{
    QSettings s = makeSettings();
    s.setValue("sensors/sensor3_id", id);
}
// ===== Cooling settings =====

bool coolingInvertLogic()
{
    QSettings s = makeSettings();
    return s.value("cooling/invert_logic", false).toBool();
}

void setCoolingInvertLogic(bool invert)
{
    QSettings s = makeSettings();
    s.setValue("cooling/invert_logic", invert);
}

} // namespace RuntimeConfig
