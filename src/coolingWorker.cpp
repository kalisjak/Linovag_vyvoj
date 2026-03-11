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
    condenserOverheatLockout_ = false;
    coolingActive_ = false;
    enabledSince_ = QDateTime::currentDateTime();

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
    condenserOverheatLockout_ = false;

    publishStateIfChanged(true);
}

void CoolingWorker::setEnabled(bool en) {
    if (enabled_ == en) return;
    enabled_ = en;

    if (!enabled_) {
        // Hard OFF
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP);
        coolingActive_ = false;
        defrostMode_ = false;
        dripHoldActive_ = false;
        startupDelayActive_ = false;
        condenserOverheatLockout_ = false;
        publishStateIfChanged(true);
        return;
    }

    // Re-enabled → apply startup delay again
    setCompressor(false);
    setFanDuty(AppConfig::COOLING_FAN_DUTY_NORMAL);
    coolingActive_ = false;
    defrostMode_ = false;
    dripHoldActive_ = false;
    condenserOverheatLockout_ = false;
    // startupDelayActive_ = true;
    // startupTimer_.restart();
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

    // Global disable (user OFF)
    if (!enabled_) {
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DRIP);
        coolingActive_ = false;
        defrostMode_ = false;
        dripHoldActive_ = false;
        startupDelayActive_ = false;
        condenserOverheatLockout_ = false;
        publishStateIfChanged();
        return;
    }

    checkScheduledDefrost();
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
    
    if (condenserTemp_ >= AppConfig::CRITICAL_TEMPERATURE_KONDENZ) {
        condenserOverheatLockout_ = true;
        coolingActive_ = false;
        setCompressor(false);
        publishStateIfChanged();
        return;
    }

    if (condenserOverheatLockout_) {
        if (condenserTemp_ > AppConfig::WARNING_TEMPERATURE_KONDENZ) {
            coolingActive_ = false;
            setCompressor(false);
            publishStateIfChanged();
            return;
        }
        condenserOverheatLockout_ = false;
    }

    // Defrost mode overrides everything
    if (defrostMode_) {
        setCompressor(false);
        setFanDuty(AppConfig::COOLING_FAN_DUTY_DEFROST); // 100%
        coolingActive_ = false;

        const bool defrostFinishedByTemp = evapTemp_ >= AppConfig::COOLING_DEFROST_STOP_TEMP;
        const bool defrostFinishedByTimeout = defrostTimer_.isValid() &&
                                             defrostTimer_.elapsed() >= AppConfig::COOLING_DEFROST_MAX_DURATION_MS;
        if (defrostFinishedByTemp || defrostFinishedByTimeout) {
            qDebug() << "[CoolingWorker]" << "Defrost ended. Evap temp:" << evapTemp_;
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
        
        if (dripTimer_.elapsed() >= AppConfig::COOLING_POST_DEFROST_HOLD_MS) {
            dripHoldActive_ = false;
            coolingActive_ = true;
            qDebug() << "[CoolingWorker]" << "Drip hold ended.";
        }
        publishStateIfChanged();
        return;
    }

    // Enter defrost when evaporator gets too cold
    if (evapTemp_ <= AppConfig::COOLING_DEFROST_START_TEMP) {
        defrostMode_ = true;
        defrostTimer_.restart();
        lastDefrostAt_ = QDateTime::currentDateTime();
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

void CoolingWorker::setAutoDefrostEnabled(bool en) {
    autoDefrostEnabled_ = en;
}

void CoolingWorker::setAutoDefrostTimes(int t1Min, int t2Min) {
    autoDefrostTime1Min_ = t1Min;
    autoDefrostTime2Min_ = t2Min;
}

int CoolingWorker::minutesSinceMidnightLocal() const {
    const QTime t = QTime::currentTime();
    return t.hour() * 60 + t.minute();
}

void CoolingWorker::checkScheduledDefrost() {
    if (!autoDefrostEnabled_) return;
    if (!enabled_) return;

    // nezasahuj do běžícího defrostu / pauzy
    if (defrostMode_ || dripHoldActive_ || startupDelayActive_) return;

    const int nowMin = minutesSinceMidnightLocal();

    const bool isMatch = (nowMin == autoDefrostTime1Min_) || (nowMin == autoDefrostTime2Min_);
    if (!isMatch) return;

    const QDateTime now = QDateTime::currentDateTime();

    // anti-double-fire (když tick běží víckrát v minutě)
    if (lastScheduledFire_.isValid()) {
        qDebug() << "[CoolingWorker]" << "Last scheduled defrost fire at:" << lastScheduledFire_.toString("yyyy-MM-dd HH:mm:ss");
        if (lastScheduledFire_.date() == now.date() &&
            lastScheduledFire_.time().hour() == now.time().hour() &&
            lastScheduledFire_.time().minute() == now.time().minute()) {
            return;
        }
    }

    // podmínka 4h od zapnutí vany
    if (enabledSince_.isValid()) {
        qDebug() << "[CoolingWorker]" << "Bath enabled since:" << enabledSince_.toString("yyyy-MM-dd HH:mm:ss") << "which is" << enabledSince_.secsTo(now) << "seconds ago";
        if (enabledSince_.secsTo(now) < minTimeAutoDefrostS_) return;
    } else {
        qDebug() << "[CoolingWorker]" << "Bath has never been enabled, skipping scheduled defrost.";
        return;
    }

    // podmínka 4h od posledního defrostu (scheduled i threshold)
    if (lastDefrostAt_.isValid()) {
        qDebug() << "[CoolingWorker]" << "Last defrost at:" << lastDefrostAt_.toString("yyyy-MM-dd HH:mm:ss") << "which is" << lastDefrostAt_.secsTo(now) << "seconds ago";
        if (lastDefrostAt_.secsTo(now) < minTimeAutoDefrostS_) return;
    }

    defrostMode_ = true;
    defrostTimer_.restart();
    lastDefrostAt_ = now;
    lastScheduledFire_ = now;
}

void CoolingWorker::publishStateIfChanged(bool force) {
    const bool c = coolingActive_;
    const bool d = defrostMode_;
    const bool p = compressorOn_;
    const bool dh = dripHoldActive_;

    if (!force && c == lastCoolingActive_ && d == lastDefrostActive_ && p == lastCompressorOn_ && dh == lastDripHoldAc_) return;

    lastCoolingActive_ = c;
    lastDefrostActive_ = d;
    lastCompressorOn_ = p;
    lastDripHoldAc_ = dh;

    emit coolingStateChanged(c, d, p, dh);
}
