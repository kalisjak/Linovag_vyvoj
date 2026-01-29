#include "coolingWorker.hpp"

#include <QDebug>

#ifdef LNVG_USE_PIGPIO
extern "C" {
#include <pigpio.h>
}
#endif

CoolingWorker::CoolingWorker(int compressorGpioPin,
                             int fanPwmGpioPin,
                             int bathIdx,
                             int evapIdx,
                             const QString& heartbeatName,
                             QObject* parent)
    : QObject(parent),
      compressorPin_(compressorGpioPin),
      fanPin_(fanPwmGpioPin),
      bathIdx_(bathIdx),
      evapIdx_(evapIdx),
      heartbeatName_(heartbeatName) {
    controlTimer_ = new QTimer(this);
    controlTimer_->setInterval(AppConfig::COOLING_CONTROL_INTERVAL_MS);
    controlTimer_->setTimerType(Qt::CoarseTimer);
    connect(controlTimer_, &QTimer::timeout, this, &CoolingWorker::tick);
}

void CoolingWorker::start() {
    hwInitialized_ = true;
    startupDelayActive_ = true;
    dripHoldActive_ = false;
    defrostMode_ = false;
    coolingActive_ = false;

#ifdef LNVG_USE_PIGPIO
    if (gpioInitialise() < 0) {
        qWarning() << "[CoolingWorker] pigpio init failed!";
        return;
    }
    // pigpio should be initialized elsewhere globally (or you can init here if desired)
    gpioSetMode(compressorPin_, PI_OUTPUT);
    gpioSetMode(fanPin_, PI_OUTPUT);
    gpioWrite(compressorPin_, 0);

    gpioSetPWMfrequency(fanPin_, AppConfig::FAN_PWM_FREQUENCY);
    gpioPWM(fanPin_, 255); // 100 % (při startu stáhlé přes pull-up) = netočí se
    // gpioHardwarePWM(fanPin_, AppConfig::FAN_PWM_FREQUENCY, 0);
    qInfo() << "[CoolingWorker] GPIO fanPWM =" << fanPin_
            << "compressor =" << compressorPin_
            << "PWM freq =" << AppConfig::FAN_PWM_FREQUENCY << "Hz";
#endif

    setCompressor(false);
    setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP); // fans OFF

    startupTimer_.restart();
    controlTimer_->start();

    publishStateIfChanged(true);
}

void CoolingWorker::stop() {
    if (controlTimer_) controlTimer_->stop();

    setCompressor(false);
    setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP);

    coolingActive_ = false;
    defrostMode_ = false;
    startupDelayActive_ = false;
    dripHoldActive_ = false;

    publishStateIfChanged(true);
}

void CoolingWorker::onTempSensors(double t1, double t2, double t3, double t4, double t5) {
    // Map indices (1..5) into our channels
    const double bath = (bathIdx_ == 1) ? t1 : t2;
    const double evap = (evapIdx_ == 3) ? t3 : t4;

    bathTemp_ = bath;
    evapTemp_ = evap;
    condenserTemp_ = t5;
}

void CoolingWorker::onTargetTempChanged(double target) { targetTemp_ = target; }

void CoolingWorker::tick() {
    emit heartbeat(heartbeatName_);

    // Startup delay: nothing runs
    if (startupDelayActive_) {
        const qint64 elapsed = startupTimer_.elapsed();
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP);
        
        coolingActive_ = false;
        
        if (elapsed >= AppConfig::COOLING_STARTUP_DELAY_MS) {
            startupDelayActive_ = false;
        }
        publishStateIfChanged();
        return;
    }
    
    // Optional: condenser warning (no control change, just debug)
    if (condenserTemp_ >= AppConfig::CRITICAL_TEMPERATURE_KONDENZ) {
        qWarning() << "[CoolingWorker]" << heartbeatName_ << "Condenser temp is too high:" << condenserTemp_;
        coolingActive_ = false;
        setCompressor(false);
        publishStateIfChanged();
        return;
    } else if (condenserTemp_ <= AppConfig::CRITICAL_TEMPERATURE_KONDENZ && condenserTemp_ >= AppConfig::WARNING_TEMPERATURE_KONDENZ) {
        qWarning() << "[CoolingWorker]" << heartbeatName_ << "Condenser temp warning level:" << condenserTemp_;
    }

    // Defrost mode overrides everything
    if (defrostMode_) {
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DEFROST); // 100%
        coolingActive_ = false;

        if (evapTemp_ >= AppConfig::COOLING_DEFROST_STOP_TEMP) {
            defrostMode_ = false;
            dripHoldActive_ = true;
            dripTimer_.restart();
            setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP); // stop fans immediately
        }
        publishStateIfChanged();
        return;
    }

    // Post-defrost drip hold
    if (dripHoldActive_) {
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP);
        coolingActive_ = true;

        if (dripTimer_.elapsed() >= AppConfig::COOLING_POST_DEFROST_HOLD_MS) {
            dripHoldActive_ = false;
        }
        publishStateIfChanged();
        return;
    }

    // Enter defrost when evaporator gets too cold
    if (evapTemp_ <= AppConfig::COOLING_DEFROST_START_TEMP) {
        defrostMode_ = true;
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DEFROST);
        coolingActive_ = false;
        publishStateIfChanged();
        return;
    }

    // Normal cycle
    coolingActive_ = true;
    setFanDuty(AppConfig::COOLING_FAN_DUTY_NORMAL); // 80% (see config mapping)

    const double onTh = targetTemp_ + AppConfig::COOLING_HYSTERESIS_DELTA;
    const double offTh = targetTemp_;

    if (!compressorOn_ && bathTemp_ >= onTh) {
        setCompressor(true);
    } else if (compressorOn_ && bathTemp_ <= offTh) {
        setCompressor(false);
    }

    publishStateIfChanged();
}

void CoolingWorker::setCompressor(bool on) {
    compressorOn_ = on;
#ifdef LNVG_USE_PIGPIO
    gpioWrite(compressorPin_, on ? 1 : 0);
#else
    // simulation: no GPIO
#endif
}

void CoolingWorker::setFanDuty(double duty) {
    if (!hwInitialized_)
        return;

    if (duty < 0.0) duty = 0.0;
    if (duty > 1.0) duty = 1.0;

#ifdef LNVG_USE_PIGPIO
    int pwm = static_cast<int>(duty * 255.0 + 0.5);
    gpioPWM(fanPin_, pwm);
#else
    Q_UNUSED(duty);
#endif
}

void CoolingWorker::publishStateIfChanged(bool force) {
    const bool c = coolingActive_;
    const bool d = defrostMode_;
    const bool p = compressorOn_;

    if (!force && c == lastCoolingActive_ && d == lastDefrostActive_ && p == lastCompressorOn_) return;

    lastCoolingActive_ = c;
    lastDefrostActive_ = d;
    lastCompressorOn_ = p;

    emit coolingStateChanged(c, d, p);
}
