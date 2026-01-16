#pragma once

#include <QString>
#include <string>
#include <QtGlobal>

namespace AppConfig {

// ========== MQTT ==========

inline const QString MQTT_BROKER_HOST        = QStringLiteral("192.168.3.101");
inline constexpr quint16 MQTT_BROKER_PORT    = 8883;
inline const QString MQTT_USERNAME           = QStringLiteral("device1");
inline const QString MQTT_PASSWORD           = QStringLiteral("pass1");
inline const QString MQTT_TOPIC_TELEMETRY    = QStringLiteral("devices/device1/telemetry");
inline const QString MQTT_CA_FILE            = QStringLiteral("/usr/local/share/ca-certificates/rootCA.pem");

// // ========== Senzory DS18B20 ==========

// inline const std::string SENSOR1_ID = "28-0b24409ff61f";
// inline const std::string SENSOR2_ID = "28-0b2440f86631";
// inline const std::string SENSOR3_ID = "28-0b2440323b08";
// inline const std::string SENSOR4_ID = "28-0b244025e0df";
// inline const std::string SENSOR5_ID = "28-0b23730ca59f";

// ========== Časy / intervaly ==========

// jak často číst senzory
inline constexpr int SENSOR_POLL_INTERVAL_MS    = 8000;    
inline constexpr int MQTT_POLL_INTERVAL_MS    = 60000;

// watchdog
inline constexpr qint64 WATCHDOG_CHECK_INTERVAL_MS = 20000;
inline constexpr qint64 WATCHDOG_TIMEOUT_MS        = 65000;  // 65 s bez heartbeat

// ========== Logování ==========

inline constexpr int        LOG_MAX_HISTORY_LINES      = 500;
inline constexpr int        LOG_MAX_FILES              = 100;
inline constexpr long long  LOG_MAX_FILE_SIZE_BYTES    = 200 * 1024; // 200 kB

// ========== Zařízení ==========

inline const QString DEVICE_SERIAL = QStringLiteral("SN-65468");

// ========== Chlazení ==========


// GPIO piny
inline constexpr int FAN_PWM_PIN      = 13;
inline constexpr int COMPRESSOR_PIN   = 6;
inline constexpr int POWER_1_PIN      = 16;
inline constexpr int POWER_2_PIN      = 26;

// PWM
inline constexpr int FAN_PWM_FREQUENCY   = 15000;   // 15 kHz

// interval řízení
inline constexpr int COOLING_CONTROL_INTERVAL_MS = 1000;

// hysteréze a defrost
inline constexpr double COOLING_HYSTERESIS_DELTA      = 2.0;   // X / X+2 °C
inline constexpr double COOLING_DEFROST_START_TEMP    = -16.0; // začátek defrostu
inline constexpr double COOLING_DEFROST_STOP_DELTA    = 3.0;   // konec při 6 °C !! TODO !!

inline constexpr double CRITICAL_TEMPERATURE_KONDENZ  = 45.0; // kritická teplota

// PWM duty hodnoty
inline constexpr double COOLING_FAN_DUTY_NORMAL  = 0.2; // 80 %
inline constexpr double COOLING_FAN_DUTY_DEFROST = 0.0; // 100 %

// start delay
inline constexpr int COOLING_STARTUP_DELAY_MS    = 5000; // 30 s

} // namespace AppConfig
