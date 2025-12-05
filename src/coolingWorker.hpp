#pragma once

#include <QObject>
#include <QTimer>
#include <QElapsedTimer>

// POZNÁMKA: používám pigpio pro PWM na 20 kHz.
// V CMakeLists.txt pak budeš muset přilinkovat -lpigpio (nebo podle tvého buildu).
// Pokud používáš něco jiného než pigpio, stačí v .cpp přepsat initGpio/applyOutputs.

class CoolingWorker : public QObject {
    Q_OBJECT
public:
    explicit CoolingWorker(QObject* parent = nullptr);
    ~CoolingWorker();

signals:
    void heartbeat(const QString& name);    // pro watchdog ("cooling")

public slots:
    void start();
    void stop();

    // vstupy z ostatních vláken
    void onTempSensors(double t1, double t2);  // senzor 1 a 2
    void onEvapTemp(double tevap);            // senzor 3 (výparník)
    void onTargetTempChanged(double t);       // požadovaná vnitřní teplota

    // jednoduchý přepínač logiky výstupu (true = aktivní HIGH, false = aktivní LOW)
    void setInvertLogic(bool invert);

private slots:
    void controlStep();   // periodická logika

private:
    // HW konfigurace
    static constexpr int kGpioPin = 13;          // PWM + kompresor (podle tvého HW)
    static constexpr int kPwmFrequency = 20000;  // 20 kHz

    // logika teplot
    // vnitřní hysteréze: vypnout při X, zapnout při X+2
    static constexpr double kHysteresisDelta = 2.0;

    // defrost (výparník, senzor 3)
    static constexpr double kDefrostStartTemp = -20.0; // při -20°C začni odmrazovat
    static constexpr double kDefrostStopDelta = 3.0;   // končit X+3 => -17 °C

    // PWM pro větráky
    static constexpr double kFanDutyNormal = 0.40;  // 40 % při běžném provozu
    static constexpr double kFanDutyDefrost = 0.80; // 80 % při odmrazování

    // start delay po spuštění programu
    static constexpr int kStartupDelayMs = 30000;   // 30 s

    QTimer* timer_ = nullptr;

    double t1_ = 0.0;
    double t2_ = 0.0;
    double tevap_ = 0.0;
    double targetTemp_ = 4.0;     // default, Backend ti to přepíše

    bool compressorOn_ = false;
    bool defrostMode_ = false;
    bool hwInitialized_ = false;

    bool invertLogic_ = false;    // false = aktivní HIGH (současný stav)
                                  // true  = aktivní LOW (budoucí inverzní logika)

    QElapsedTimer startupTimer_;
    bool startupDelayActive_ = true;

    void initGpio();
    void applyOutputs();
    void setFanDuty(double duty);     // 0.0 - 1.0
    void setCompressor(bool on);      // logický stav (před inverzí)
};
