#pragma once

#ifndef LNVG_USE_PIGPIO
#include <QFile>
#include <QTextStream>
#endif

#include <QElapsedTimer>
#include <QObject>
#include <QString>
#include <QTimer>

#include "config.hpp"
#include "runtimeConfig.hpp"

class CoolingWorker : public QObject {
    Q_OBJECT
   public:
    explicit CoolingWorker(QObject* parent = nullptr);
    bool coolingActive() const { return coolingActive_; }
    bool defrostActive() const { return defrostMode_; }
    bool compressorOn()  const { return compressorOn_; }

    ~CoolingWorker();

   signals:
    // pro watchdog
    void heartbeat(const QString& name);

    void coolingStateChanged(bool coolingActive,
                             bool defrostActive,
                             bool compressorOn);

   public slots:
    // start/stop vlákna
    void start();
    void stop();

    // vstupy z ostatních vláken
    void onTempSensors(double t1, double t2);  // senzor 1 a 2 – průměr pro kompresor
    void onEvapTemp(double tevap);             // senzor 3 – výparník (defrost)
    void onTargetTempChanged(double t);        // cílová vnitřní teplota X°C

    // přepínač inverzní logiky kompresoru (uloží se do RuntimeConfig)
    void setInvertLogic(bool invert);
    bool invertLogic() const { return invertLogic_; }

   private slots:
    void controlStep();  // periodická regulační logika

   private:
    QTimer* timer_ = nullptr;
    QElapsedTimer startupTimer_;

    double t1_ = 0.0;
    double t2_ = 0.0;
    double tevap_ = 0.0;
    double targetTemp_ = 4.0;  // default, backend ti ho přepíše

    bool compressorOn_ = false;
    bool defrostMode_ = false;
    bool hwInitialized_ = false;
    bool startupDelayActive_ = true;
    bool invertLogic_ = false;  // false = aktivní HIGH, true = aktivní LOW
    bool coolingActive_ = false;

#ifndef LNVG_USE_PIGPIO
    QFile simFile_;
    QTextStream simStream_;
#endif

    void initGpio();
    void shutdownGpio();

    void setFanDuty(double duty);  // 0.0–1.0
    void setCompressor(bool on);   // logický stav (před inverzí)

    void emitCoolingState();
};
