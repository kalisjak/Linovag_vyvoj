#pragma once

#include <QString>
#include <string>
#include <QtGlobal>

namespace AppConfig {

// ========== MQTT ==========
inline const QString MQTT_BROKER_HOST        = QStringLiteral("194.228.245.109");
inline constexpr quint16 MQTT_BROKER_PORT    = 8883;
inline const QString MQTT_USERNAME           = QStringLiteral("device2");
inline const QString MQTT_PASSWORD           = QStringLiteral("pass2");
inline const QString MQTT_TOPIC_TELEMETRY    = QStringLiteral("devices/device1/telemetry");
inline const QString MQTT_CA_FILE            = QStringLiteral("/usr/local/share/ca-certificates/rootCA.pem");

// ========== Časy / intervaly ==========
// jak často číst senzory
inline constexpr int SENSOR_POLL_INTERVAL_MS = 8000;
inline constexpr int MQTT_POLL_INTERVAL_MS   = 60000;

inline constexpr uint MIN_TIME_BEETWEEN_AUTODEFROST_S = 4 * 3600; // minimální interval mezi defrosty (4h) 4 * 3600

// watchdog
inline constexpr qint64 WATCHDOG_CHECK_INTERVAL_MS = 20000;
inline constexpr qint64 WATCHDOG_TIMEOUT_MS        = 65000;  // 65 s bez heartbeat

// ========== Logování ==========
inline constexpr int        LOG_MAX_HISTORY_LINES   = 500;
inline constexpr int        LOG_MAX_FILES           = 100;
inline constexpr long long  LOG_MAX_FILE_SIZE_BYTES = 200 * 1024; // 200 kB

// cache v RAM (kolik řádků se drží než se zapíše na SD)
inline constexpr int        LOG_CACHE_LINES          = 15;

// interval pro snapshot teplot do temps_log_*.txt (nezávislé na SENSOR_POLL_INTERVAL_MS)
inline constexpr int        TEMPS_LOG_INTERVAL_MS    = 30000;


// ========== Chlazení ==========

// GPIO piny (kompresory)
inline constexpr int COMPRESSOR1_PIN = 6;
inline constexpr int COMPRESSOR2_PIN = 5;  // pro typ 2+2

// GPIO piny (zasuvky)
inline constexpr int POWER_1_PIN      = 16;
inline constexpr int POWER_2_PIN      = 26;

// PWM ventilátoru (společné řízení; duty je už správně nastavené v konstantách)
inline constexpr int FAN_PWM1_PIN        = 13;
inline constexpr int FAN_PWM2_PIN      = 19;
inline constexpr int FAN_PWM_FREQUENCY  = 15000;   // 15 kHz

// interval řízení
inline constexpr int COOLING_CONTROL_INTERVAL_MS = 1000;

// hysteréze a defrost
inline constexpr double COOLING_HYSTERESIS_DELTA      = 2.0;   // X / X+2 °C
inline constexpr double COOLING_DEFROST_START_TEMP    = -16.0; // začátek defrostu
inline constexpr double COOLING_DEFROST_STOP_TEMP     = 8.0;   // konec defrostu

// teplota kondenzátoru pro varování
inline constexpr double CRITICAL_TEMPERATURE_KONDENZ  = 45.0;
inline constexpr double WARNING_TEMPERATURE_KONDENZ   = 40.0;

// PWM duty hodnoty
inline constexpr double COOLING_FAN_DUTY_NORMAL  = 0.2; // 80 %
inline constexpr double COOLING_FAN_DUTY_DEFROST = 0.0; // 100 %
inline constexpr double COOLING_FAN_DUTY_DRIP    = 1.0; // 0 % (odkapání)

// start delay
inline constexpr int COOLING_STARTUP_DELAY_MS    = 5000;

// odkapání po defrostu
inline constexpr int COOLING_POST_DEFROST_HOLD_MS = 2 * 60 * 1000;

// ========== Vlhkost (DHT22/AM2302) ==========
// GPIO pin pro DHT22 (lze přepsat v lnvg_app.conf)
inline constexpr int DHT22_GPIO = 10;

// ========== Kontrola RPM ventilátorů ==========
// 2 pulzy na otáčku
inline constexpr int FAN_TACH_PULSES_PER_REV = 2;
// otáčky při 100 % výkonu
inline constexpr int FAN_RPM_AT_100 = 1800;
// tolerance (např. 0.15 = 15 %)
inline constexpr double FAN_RPM_TOLERANCE = 0.15;

// tach vstupy (vana typ-3 používá 22,23,24; typ 2+2 navíc 27)
inline constexpr int FAN_TACH_PIN_1 = 22;
inline constexpr int FAN_TACH_PIN_2 = 23;
inline constexpr int FAN_TACH_PIN_3 = 24;
inline constexpr int FAN_TACH_PIN_4 = 27;

} // namespace AppConfig
