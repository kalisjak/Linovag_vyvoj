#include <pigpio.h>

#include <chrono>
#include <csignal>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>

// ===== Nastavení regulace =====
const int FAN_GPIO = 13;        // PWM výstup
const int PWM_FREQ_HZ = 20000;  // 20 kHz
const int DUTY_MIN_PCT = 10;    // 20 %
const int DUTY_MAX_PCT = 100;   // 100 %
const float T_LOW_C = 1.0f;
const float T_HIGH_C = 5.0f;
const int PWM_RANGE = 1000000;  // pigpio HW PWM scale 0–1M

volatile bool running = true;

// ================ DS18B20 READ FUNCTION =======================
double readDS18B20(const std::string& deviceId) {
    std::string path = "/sys/bus/w1/devices/" + deviceId + "/w1_slave";
    std::ifstream file(path);
    if (!file.is_open()) return -999.0;

    std::string line;
    std::getline(file, line);
    if (line.find("YES") == std::string::npos) return -999.0;

    std::getline(file, line);
    auto pos = line.find("t=");
    if (pos == std::string::npos) return -999.0;

    int temp_milli = std::stoi(line.substr(pos + 2));
    return temp_milli / 1000.0;  // -> °C
}

// ================ DUTY COMPUTATION ============================
float compute_duty_pct(float tempC) {
    if (tempC <= T_LOW_C) return DUTY_MIN_PCT;
    if (tempC >= T_HIGH_C) return DUTY_MAX_PCT;

    float k = (tempC - T_LOW_C) / (T_HIGH_C - T_LOW_C);
    return DUTY_MIN_PCT + k * (DUTY_MAX_PCT - DUTY_MIN_PCT);
}

// ================ SIGNAL HANDLER ===============================
void signal_handler(int) { running = false; }

// ================ MAIN PROGRAM ================================
int main() {
    std::string deviceId = "28-0b24409ff61f";  // <<< TVÉ ID DS18B20

    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);

    if (gpioInitialise() < 0) {
        std::cerr << "Nepodařilo se inicializovat pigpio." << std::endl;
        return 1;
    }

    int actual_freq = gpioSetPWMfrequency(FAN_GPIO, PWM_FREQ_HZ);
    if (actual_freq <= 0) {
        std::cerr << "Chyba při nastavování PWM frekvence." << std::endl;
        gpioTerminate();
        return 1;
    }

    gpioSetPWMrange(FAN_GPIO, PWM_RANGE);

    std::cout << "PWM frekvence: " << actual_freq << " Hz" << std::endl;

    // hlavní smyčka
    while (running) {
        double temp = readDS18B20(deviceId);

        if (temp == -999.0) {
            std::cerr << "[WARN] Nelze číst DS18B20" << std::endl;
            // Můžeš tu nastavit fail-safe -> třeba ventilátor na 100 %
            gpioHardwarePWM(FAN_GPIO, PWM_FREQ_HZ, PWM_RANGE);
        } else {
            float duty_pct = compute_duty_pct(temp);
            int duty_raw = static_cast<int>((duty_pct / 100.0f) * PWM_RANGE);

            // invert PWM – 0 = MAX, 1'000'000 = STOP
            // int duty_raw_inv = PWM_RANGE - duty_raw;
            int duty_raw_inv = 0;  // minimální duty 35 %
            gpioHardwarePWM(FAN_GPIO, PWM_FREQ_HZ, duty_raw_inv);

            std::cout << "T=" << temp << " °C, duty=" << duty_pct << "% (raw " << duty_raw_inv << " inverted)" << std::endl;
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(500));  // 2×/s
    }

    gpioHardwarePWM(FAN_GPIO, PWM_FREQ_HZ, 0);
    gpioTerminate();
    return 0;
}
