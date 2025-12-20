#include "coolingWorker.hpp"

#include <QDebug>

#ifdef LNVG_USE_PIGPIO
extern "C" {
#include <pigpio.h>
}
#endif

CoolingWorker::CoolingWorker(QObject* parent)
    : QObject(parent)
{
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout,
            this, &CoolingWorker::controlStep);

    // načti poslední stav inverzní logiky z runtime configu
    invertLogic_ = RuntimeConfig::coolingInvertLogic();
}

CoolingWorker::~CoolingWorker()
{
    stop();
    shutdownGpio();
}

void CoolingWorker::start()
{
    qInfo() << "[CoolingWorker] start()";

    startupDelayActive_ = true;
    startupTimer_.restart();

    initGpio();

    // perioda řídicí smyčky z configu
    timer_->start(AppConfig::COOLING_CONTROL_INTERVAL_MS);
}

void CoolingWorker::stop()
{
    if (timer_) {
        timer_->stop();
    }
}

void CoolingWorker::onTempSensors(double t1, double t2)
{
    t1_ = t1;
    t2_ = t2;
}

void CoolingWorker::onEvapTemp(double tevap)
{
    tevap_ = tevap;
}

void CoolingWorker::onTargetTempChanged(double t)
{
    targetTemp_ = t;
}

void CoolingWorker::setInvertLogic(bool invert)
{
    if (invertLogic_ == invert)
        return;

    invertLogic_ = invert;
    RuntimeConfig::setCoolingInvertLogic(invertLogic_);

    qInfo() << "[CoolingWorker] invertLogic set to" << invertLogic_;

    // hned aplikujeme "vypnutý" stav podle nové logiky
    if (hwInitialized_) {
        setCompressor(compressorOn_);
    }
}

void CoolingWorker::initGpio()
{
    if (hwInitialized_)
        return;

#ifdef LNVG_USE_PIGPIO
    if (gpioInitialise() < 0) {
        qWarning() << "[CoolingWorker] pigpio init failed!";
        return;
    }

    gpioSetMode(AppConfig::FAN_PWM_PIN, PI_OUTPUT);
    gpioSetPWMfrequency(AppConfig::FAN_PWM_PIN, AppConfig::FAN_PWM_FREQUENCY);
    gpioPWM(AppConfig::FAN_PWM_PIN, 255); // 100 % (při startu stáhlé přes pull-up) = netočí se

    gpioSetMode(AppConfig::COMPRESSOR_PIN, PI_OUTPUT);
    bool offLevel = invertLogic_ ? 1 : 0;
    gpioWrite(AppConfig::COMPRESSOR_PIN, offLevel);

    qInfo() << "[CoolingWorker] GPIO fanPWM =" << AppConfig::FAN_PWM_PIN
            << "compressor =" << AppConfig::COMPRESSOR_PIN
            << "PWM freq =" << AppConfig::FAN_PWM_FREQUENCY << "Hz";
#else
    // simulace – otevřeme log soubor
    if (!simFile_.isOpen()) {
        simFile_.setFileName("cooling_sim.log");
        if (!simFile_.open(QIODevice::Append | QIODevice::Text)) {
            qWarning() << "[CoolingWorker] Cannot open cooling_sim.log for simulation";
        } else {
            simStream_.setDevice(&simFile_);
            simStream_ << "=== Cooling simulation started ===\n";
            simStream_.flush();
        }
    }
    qInfo() << "[CoolingWorker] Simulation mode (no GPIO)";
#endif

    hwInitialized_ = true;
}


void CoolingWorker::shutdownGpio()
{
    if (!hwInitialized_)
        return;

#ifdef LNVG_USE_PIGPIO
    setFanDuty(1.0);
    setCompressor(false);
    gpioTerminate();
#else
    if (simFile_.isOpen()) {
        simStream_ << "=== Cooling simulation ended ===\n";
        simStream_.flush();
        simFile_.close();
    }
#endif

    hwInitialized_ = false;
}

void CoolingWorker::setFanDuty(double duty)
{
    if (!hwInitialized_)
        return;

    if (duty < 0.0) duty = 0.0;
    if (duty > 1.0) duty = 1.0;

#ifdef LNVG_USE_PIGPIO
    int pwm = static_cast<int>(duty * 255.0 + 0.5);
    gpioPWM(AppConfig::FAN_PWM_PIN, pwm);
#else
    if (simFile_.isOpen()) {
        simStream_ << "Fan duty set to " << duty << "\n";
        simStream_.flush();
    } else {
        qDebug() << "[CoolingWorker][SIM] Fan duty =" << duty;
    }
#endif
}

void CoolingWorker::emitCoolingState()
{
    const bool cooling = compressorOn_ && !defrostMode_; // moje definice
    if (coolingActive_ != cooling) {
        coolingActive_ = cooling;
    }

    emit coolingStateChanged(coolingActive_, defrostMode_, compressorOn_);
}


void CoolingWorker::setCompressor(bool on)
{
    if (!hwInitialized_)
        return;

#ifdef LNVG_USE_PIGPIO
    gpioWrite(AppConfig::COMPRESSOR_PIN, on ? 1 : 0);
#else
    if (simFile_.isOpen()) {
        simStream_ << "Compressor " << (on ? "ON" : "OFF") << "\n";
        simStream_.flush();
    } else {
        qDebug() << "[CoolingWorker][SIM] Compressor" << (on ? "ON" : "OFF");
    }
#endif
}


void CoolingWorker::controlStep()
{
    emit heartbeat(QStringLiteral("cooling"));

    // start delay – prvních X ms vůbec nic nezapínat
    if (startupDelayActive_) {
        if (startupTimer_.elapsed() < AppConfig::COOLING_STARTUP_DELAY_MS) {
            setFanDuty(1.0);
            setCompressor(false);
            return;
        }
        startupDelayActive_ = false;
        qInfo() << "[CoolingWorker] startup delay finished, enabling control";
    }

    // průměr ze senzoru 1 a 2
    const double avg = (t1_ + t2_) / 2.0;

    // --- Post-defrost pauza (odkapání): 2 min kompresor i větráky OFF ---
    // Požadavek: bezprostředně po ukončení odmražování držet vše vypnuté 2 min,
    // poté se vrátit do normálního cyklu (hystereze + případný restart chlazení).
    static bool postDefrostHold_ = false;
    static QElapsedTimer postDefrostHoldTimer_;

    if (postDefrostHold_) {
        constexpr qint64 POST_DEFROST_HOLD_MS = 2 * 60 * 1000;
        if (!postDefrostHoldTimer_.isValid()) {
            postDefrostHoldTimer_.start();
        }

        if (postDefrostHoldTimer_.elapsed() < POST_DEFROST_HOLD_MS) {
            // během pauzy: vše OFF
            compressorOn_ = false;
            setCompressor(false);
            setFanDuty(0.0);
            return;
        }

        postDefrostHold_ = false;
        qInfo() << "[CoolingWorker] post-defrost hold finished, resuming normal cycle";
    }


    // --- DEFROST logika podle výparníku (senzor 3) ---
    // Požadavek: odmrazování startuje při tevap <= -20 °C (viz config),
    // ale pouze pokud právě běží chlazení (kompresor je ON).
    // Odmrazování končí při tevap >= +6 °C (pevná hodnota).
    constexpr double DEFROST_STOP_TEMP = 6.0;

    if (!defrostMode_) {
        // vstup do defrostu
        if (compressorOn_ && (tevap_ <= AppConfig::COOLING_DEFROST_START_TEMP)) {
            defrostMode_ = true;

            // DŮLEŽITÉ: okamžitě srovnat SW stav kompresoru s HW stavem,
            // aby TopBar správně ukázal "OFF" během odmražování.
            compressorOn_ = false;

            qInfo() << "[CoolingWorker] DEFROST START, tevap =" << tevap_;
            emitCoolingState();
        }
    } else {
        // výstup z defrostu (pevná teplota na výparníku)
        if (tevap_ >= DEFROST_STOP_TEMP) {
            defrostMode_ = false;
            // po odmrazu drž 2 min vše vypnuté (odkapání)
            postDefrostHold_ = true;
            postDefrostHoldTimer_.restart();
            compressorOn_ = false;
            qInfo() << "[CoolingWorker] DEFROST STOP, tevap =" << tevap_;
            emitCoolingState();
            // okamžitě po odmrazu vypnout HW a přejít do post-defrost pauzy
            setCompressor(false);
            setFanDuty(0.0);
            return;
        }
    }

    if (defrostMode_) {
        // defrost režim: kompresor OFF, větráky na 80 %
        const bool wasOn = compressorOn_;
        compressorOn_ = false;
        if (wasOn) {
            emitCoolingState();
        }

        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DEFROST);
        return;
    }

    // --- Běžná hysteréze kompresoru podle vnitřní teploty ---

    if (compressorOn_) {
        // vypnout při X °C
        if (avg <= targetTemp_) {
            compressorOn_ = false;
            qInfo() << "[CoolingWorker] Compressor OFF, avg =" << avg;
            emitCoolingState();
        }
    } else {
        // zapnout při X + 2 °C (delta z configu)
        if (avg >= targetTemp_ + AppConfig::COOLING_HYSTERESIS_DELTA) {
            compressorOn_ = true;
            qInfo() << "[CoolingWorker] Compressor ON, avg =" << avg;
            emitCoolingState();
        }
    }

    // běžný režim: kompresor podle hysteréze, větráky 40 %
    setCompressor(compressorOn_);
    setFanDuty(AppConfig::COOLING_FAN_DUTY_NORMAL);
}
