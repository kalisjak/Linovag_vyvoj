#include "powerWorker.hpp"

#include <QDebug>

#ifdef LNVG_USE_PIGPIO
extern "C" {
#include <pigpio.h>
}
#endif

PowerWorker::PowerWorker(int power1Pin, int power2Pin, QObject* parent)
    : QObject(parent)
    , power1Pin_(power1Pin)
    , power2Pin_(power2Pin)
{
}

PowerWorker::~PowerWorker()
{
    shutdownGpio();
}

void PowerWorker::initGpio()
{
    if (hwInitialized_) return;

#ifdef LNVG_USE_PIGPIO
    const int rc = gpioInitialise();
    if (rc < 0) {
        qWarning() << "[PowerWorker] pigpio init failed";
        return;
    }

    if (power1Pin_ >= 0) gpioSetMode(power1Pin_, PI_OUTPUT);
    if (power2Pin_ >= 0) gpioSetMode(power2Pin_, PI_OUTPUT);
#endif

    hwInitialized_ = true;
}

void PowerWorker::shutdownGpio()
{
    if (!hwInitialized_) return;

#ifdef LNVG_USE_PIGPIO
    if (power1Pin_ >= 0) gpioWrite(power1Pin_, 0);
    if (power2Pin_ >= 0) gpioWrite(power2Pin_, 0);
    // gpioTerminate() intentionally not called (shared process-wide)
#endif

    hwInitialized_ = false;
}

void PowerWorker::writePin(int pin, bool on)
{
    if (pin < 0) {
        qInfo() << "[PowerWorker] pin not configured, ignoring" << (on ? "ON" : "OFF");
        return;
    }

    if (!hwInitialized_) initGpio();

#ifdef LNVG_USE_PIGPIO
    if (hwInitialized_) gpioWrite(pin, on ? 1 : 0);
#else
    qInfo() << "[PowerWorker][SIM] pin" << pin << (on ? "ON" : "OFF");
#endif
}

void PowerWorker::setPower1(bool on)
{
    writePin(power1Pin_, on);
}

void PowerWorker::setPower2(bool on)
{
    writePin(power2Pin_, on);
}
