#include <algorithm>
#include <array>
#include <cerrno>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <linux/spi/spidev.h>
#include <numeric>
#include <stdexcept>
#include <string>
#include <sys/ioctl.h>
#include <unistd.h>
#include <vector>

// ===================== Nastavení HW a NTC =====================

// SPI zařízení pro CE0 (GPIO8), na RPi 4B typicky:
static constexpr const char* SPI_DEV = "/dev/spidev0.0";

// SPI parametry
static constexpr uint32_t SPI_HZ = 100000; // 100 kHz (nižší kvůli rušení a kabeláži)
static constexpr uint8_t  SPI_MODE = SPI_MODE_0;
static constexpr uint8_t  SPI_BITS = 8;

// MCP3208
static constexpr int ADC_BITS = 12;
static constexpr int ADC_MAX  = (1 << ADC_BITS) - 1; // 4095

// Reference
static constexpr double VREF = 3.3; // Vref MCP3208

// Dělič: referenční odpor (0.1%)
static constexpr double R_REF = 10000.0; // 10k

// NTC parametry
static constexpr double R0 = 10000.0;     // 10k @ 25°C
static constexpr double T0 = 25.0 + 273.15; // 298.15 K
static constexpr double BETA = 3435.0;

// Zapojení děliče:
// Varianta A (běžná): VREF -- R_REF --(uzel)-> ADC_CH -- NTC -- GND
// Pak: Vout = Vref * Rntc/(Rref + Rntc) => Rntc = Rref * Vout/(Vref - Vout)
static constexpr bool NTC_TO_GND = true;

// Vzorkování
static constexpr int TOTAL_SAMPLES = 33;  // 32+1 (první zahodit)
static constexpr int DISCARD_FIRST = 1;
static constexpr int USED_AFTER_DISCARD = TOTAL_SAMPLES - DISCARD_FIRST; // 32
static constexpr int DISCARD_MINMAX = 2;  // min + max
static constexpr int AVERAGE_COUNT = USED_AFTER_DISCARD - DISCARD_MINMAX; // 30

// =============================================================

class SpiDev {
public:
    explicit SpiDev(const char* path) {
        fd_ = ::open(path, O_RDWR);
        if (fd_ < 0) {
            throw std::runtime_error("open(" + std::string(path) + ") failed: " + std::string(std::strerror(errno)));
        }

        // mode
        uint8_t mode = SPI_MODE;
        if (ioctl(fd_, SPI_IOC_WR_MODE, &mode) == -1) {
            throw std::runtime_error("SPI_IOC_WR_MODE failed: " + std::string(std::strerror(errno)));
        }

        // bits per word
        uint8_t bits = SPI_BITS;
        if (ioctl(fd_, SPI_IOC_WR_BITS_PER_WORD, &bits) == -1) {
            throw std::runtime_error("SPI_IOC_WR_BITS_PER_WORD failed: " + std::string(std::strerror(errno)));
        }

        // speed
        uint32_t speed = SPI_HZ;
        if (ioctl(fd_, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1) {
            throw std::runtime_error("SPI_IOC_WR_MAX_SPEED_HZ failed: " + std::string(std::strerror(errno)));
        }
    }

    ~SpiDev() {
        if (fd_ >= 0) ::close(fd_);
    }

    SpiDev(const SpiDev&) = delete;
    SpiDev& operator=(const SpiDev&) = delete;

    uint16_t read_mcp3208_channel(uint8_t ch) {
        if (ch > 7) throw std::invalid_argument("channel must be 0..7");

        // MCP3208 frame (single-ended):
        // Start=1, SGL=1, D2 D1 D0, then 1 null bit, then 12 data bits
        // Prakticky: 3 bajty přes SPI a z RX složit 12-bit výsledek.
        uint8_t tx[3] = {0, 0, 0};
        uint8_t rx[3] = {0, 0, 0};

        tx[0] = static_cast<uint8_t>(0x06 | ((ch & 0x07) >> 2)); // 0b00000110 + top bit channel
        tx[1] = static_cast<uint8_t>((ch & 0x03) << 6);          // remaining channel bits
        tx[2] = 0x00;

        struct spi_ioc_transfer tr {};
        tr.tx_buf = reinterpret_cast<unsigned long>(tx);
        tr.rx_buf = reinterpret_cast<unsigned long>(rx);
        tr.len = 3;
        tr.speed_hz = SPI_HZ;
        tr.bits_per_word = SPI_BITS;
        tr.delay_usecs = 0;

        if (ioctl(fd_, SPI_IOC_MESSAGE(1), &tr) < 1) {
            throw std::runtime_error("SPI_IOC_MESSAGE failed: " + std::string(std::strerror(errno)));
        }

        // 12-bit data: lower 4 bits of rx[1] + rx[2]
        uint16_t value = static_cast<uint16_t>(((rx[1] & 0x0F) << 8) | rx[2]);
        value &= ADC_MAX;
        return value;
    }

private:
    int fd_{-1};
};

static double adc_to_voltage(uint16_t adc) {
    return (static_cast<double>(adc) / static_cast<double>(ADC_MAX)) * VREF;
}

static double voltage_to_resistance(double v) {
    // Ošetření okrajů, aby nedošlo k dělení nulou / log(0)
    const double eps = 1e-9;
    v = std::clamp(v, eps, VREF - eps);

    if (NTC_TO_GND) {
        // Rntc = Rref * Vout/(Vref - Vout)
        return R_REF * (v / (VREF - v));
    } else {
        // Varianta B: VREF -- NTC --(uzel)-> ADC -- R_REF -- GND
        // Vout = Vref * Rref/(Rref + Rntc) => Rntc = Rref*(Vref/Vout - 1)
        return R_REF * (VREF / v - 1.0);
    }
}

static double resistance_to_celsius(double r) {
    // Beta rovnice: 1/T = 1/T0 + (1/B)*ln(R/R0)
    const double invT = (1.0 / T0) + (1.0 / BETA) * std::log(r / R0);
    const double T = 1.0 / invT; // Kelvin
    return T - 273.15;
}

static double robust_average_33(const std::vector<uint16_t>& samples33) {
    if (static_cast<int>(samples33.size()) != TOTAL_SAMPLES) {
        throw std::invalid_argument("Need exactly 33 samples");
    }

    // 1) zahodit první
    std::vector<uint16_t> s(samples33.begin() + DISCARD_FIRST, samples33.end()); // 32 ks

    // 2) najít min a max
    auto [mn_it, mx_it] = std::minmax_element(s.begin(), s.end());
    const uint16_t mn = *mn_it;
    const uint16_t mx = *mx_it;

    // 3) sečíst bez jednoho výskytu min a jednoho výskytu max
    // (pokud se min==max, zahodí se "dvě" hodnoty stejné => stále OK)
    bool removed_min = false;
    bool removed_max = false;
    long long sum = 0;
    int count = 0;

    for (uint16_t v : s) {
        if (!removed_min && v == mn) { removed_min = true; continue; }
        if (!removed_max && v == mx) { removed_max = true; continue; }
        sum += v;
        count++;
    }

    if (count != AVERAGE_COUNT) {
        throw std::runtime_error("Unexpected average count: " + std::to_string(count));
    }

    return static_cast<double>(sum) / static_cast<double>(count);
}

int main(int argc, char** argv) {
    try {
        SpiDev spi(SPI_DEV);

        // Jednorázové vyčtení všech 8 kanálů
        for (uint8_t ch = 0; ch < 8; ++ch) {
            std::vector<uint16_t> samples;
            samples.reserve(TOTAL_SAMPLES);

            for (int i = 0; i < TOTAL_SAMPLES; ++i) {
                uint16_t adc = spi.read_mcp3208_channel(ch);
                samples.push_back(adc);

                // Krátká pauza může pomoct ve velmi rušném prostředí
                // (zvlášť s RC článkem 1k/100n => tau ~100 µs)
                // usleep(200); // 200 µs - můžeš odkomentovat, pokud chceš
            }

            double avg_adc = robust_average_33(samples);
            double v = adc_to_voltage(static_cast<uint16_t>(std::lround(avg_adc)));
            double r = voltage_to_resistance(v);
            double c = resistance_to_celsius(r);

            std::cout << "CH" << int(ch)
                      << ": ADC_avg=" << avg_adc
                      << "  V=" << v
                      << " V  R=" << r
                      << " ohm  T=" << c
                      << " °C\n";
        }

        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }
}