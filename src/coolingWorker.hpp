#pragma once

#include <QObject>
#include <QElapsedTimer>
#include <QTimer>
#include <QString>

#include "config.hpp"

class CoolingWorker : public QObject {
    Q_OBJECT

   public:
    // bathIdx: 1 or 2 (maps to DS18 t1/t2)
    // evapIdx: 3 or 4 (maps to DS18 t3/t4)
    // condenser is always DS18 t5
    explicit CoolingWorker(int compressorGpioPin,
                           int fanPwmGpioPin,
                           int bathIdx,
                           int evapIdx,
                           const QString& heartbeatName,
                           QObject* parent = nullptr);

   public slots:
    void start();
    void stop();

    // Enable/disable the whole bath (fans OFF + compressor OFF when disabled).
    // When re-enabled, startup delay is re-applied to protect compressor.
    void setEnabled(bool en);

    void onTempSensors(double t1, double t2, double t3, double t4, double t5);
    void onTargetTempChanged(double target);

   signals:
    void coolingStateChanged(bool coolingActive, bool defrostActive, bool compressorOn, bool dripActive);
    void heartbeat(const QString& name);

   private:
    void tick();

    void setCompressor(bool on);
    void setFanDuty(double duty);

    const int compressorPin_;
    const int fanPin_;
    const int bathIdx_;
    const int evapIdx_;
    const QString heartbeatName_;

    QTimer* controlTimer_ = nullptr;

    // latest sensor values
    double bathTemp_ = 0.0;
    double evapTemp_ = 0.0;
    double condenserTemp_ = 0.0;
    double targetTemp_ = 5.0;

    // state flags requested by user
    bool compressorOn_ = false;
    bool defrostMode_ = false;
    bool hwInitialized_ = false;
    bool startupDelayActive_ = true;
    bool coolingActive_ = false;

    bool dripHoldActive_ = false;

    bool enabled_ = true;

    QElapsedTimer startupTimer_;
    QElapsedTimer dripTimer_;

    void publishStateIfChanged(bool force = false);
    bool lastCoolingActive_ = false;
    bool lastDefrostActive_ = false;
    bool lastCompressorOn_ = false;
    bool lastDripHoldAc_ = false;
};
