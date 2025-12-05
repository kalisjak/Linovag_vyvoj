#include "CoolingWorker.hpp"

#include <QDebug>

extern "C" {
#include <pigpio.h>
}

CoolingWorker::CoolingWorker(QObject* parent)
    : QObject(parent)
{
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout,
            this, &CoolingWorker::controlStep);
}

CoolingWorker::~CoolingWorker()
{
    stop();
    if (hwInitialized_) {
        // vypneme výstupy
        setFanDuty(0.0);
        setCompressor(false);
        gpioTerminate();
        hwInitialized_ = false;
    }
}

void CoolingWorker::start()
{
    qInfo() << "[CoolingWorker] start()";

    startupDelayActive_ = true;
    startupTimer_.start();

    initGpio();

    // perioda logiky – stačí např. 1s
    timer_->start(1000);
}

void CoolingWorker::stop()
{
    if (timer_) timer_->stop();
    // výstupy se vypnou v destruktoru / při restartu
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
    invertLogic_ = invert;
    qInfo() << "[CoolingWorker] invertLogic =" << invertLogic_;
}

void CoolingWorker::initGpio()
{
    if (hwInitialized_) return;

    if (gpioInitialise() < 0) {
        qWarning() << "[CoolingWorker] pigpio init failed!";
        return;
    }

    gpioSetMode(kGpioPin, PI_OUTPUT);

    // nastavit PWM
    gpioSetPWMfrequency(kGpioPin, kPwmFrequency);
    gpioPWM(kGpioPin, 0);

    hwInitialized_ = true;

    qInfo() << "[CoolingWorker] GPIO" << kGpioPin
            << "initialized, PWM freq =" << kPwmFrequency << "Hz";
}

void CoolingWorker::setFanDuty(double duty)
{
    if (!hwInitialized_) return;

    if (duty < 0.0) duty = 0.0;
    if (duty > 1.0) duty = 1.0;

    // pigpio: 0-255
    int pwm = static_cast<int>(duty * 255.0 + 0.5);

    // větráky jsou PWM, kompresor je ON/OFF.
    // Předpoklad: PWM řídí vstup 4-pin ventilátorů, kompresor je spínán paralelně
    // přes stejný pin (tvůj HW si případně uprav).
    gpioPWM(kGpioPin, pwm);
}

void CoolingWorker::setCompressor(bool on)
{
    if (!hwInitialized_) return;

    bool level = on;
    if (invertLogic_) {
        level = !level;
    }

    gpioWrite(kGpioPin, level ? 1 : 0);
}

void CoolingWorker::controlStep()
{
    emit heartbeat("cooling");

    // 30s delay po startu – kompresor a větráky OFF
    if (startupDelayActive_) {
        if (startupTimer_.elapsed() < kStartupDelayMs) {
            setFanDuty(0.0);
            setCompressor(false);
            return;
        }
        startupDelayActive_ = false;
        qInfo() << "[CoolingWorker] Startup delay finished, enabling control";
    }

    // 1) průměr ze senzoru 1 a 2
    const double avg = (t1_ + t2_) / 2.0;

    // 3) defrost logika z čidla výparníku
    if (!defrostMode_) {
        // vstup do defrostu
        if (tevap_ <= kDefrostStartTemp) {
            defrostMode_ = true;
            qInfo() << "[CoolingWorker] DEFROST START, tevap =" << tevap_;
        }
    } else {
        // výstup z defrostu
        if (tevap_ >= kDefrostStartTemp + kDefrostStopDelta) {
            defrostMode_ = false;
            qInfo() << "[CoolingWorker] DEFROST STOP, tevap =" << tevap_;
        }
    }

    if (defrostMode_) {
        // defrost: kompresor vždy OFF, větráky 80%
        compressorOn_ = false;
        setCompressor(false);
        setFanDuty(kFanDutyDefrost);
        return;
    }

    // 2) běžná hysteréze pro kompresor podle průměru vnitřních teplot
    if (compressorOn_) {
        // vypínáme při X °C (targetTemp_)
        if (avg <= targetTemp_) {
            compressorOn_ = false;
            qInfo() << "[CoolingWorker] Compressor OFF, avg =" << avg;
        }
    } else {
        // zapínáme při X + 2 °C
        if (avg >= targetTemp_ + kHysteresisDelta) {
            compressorOn_ = true;
            qInfo() << "[CoolingWorker] Compressor ON, avg =" << avg;
        }
    }

    // běžný režim: kompresor podle hysteréze, větráky 40 %
    setCompressor(compressorOn_);
    setFanDuty(kFanDutyNormal);
}
