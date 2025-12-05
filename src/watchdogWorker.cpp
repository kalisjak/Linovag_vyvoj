#include "watchdogWorker.hpp"

#include <QDateTime>
#include <QDebug>
#include <QTimer>

WatchdogWorker::WatchdogWorker(QObject* parent) : QObject(parent) {
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &WatchdogWorker::check);
}

void WatchdogWorker::start() {
    timer_->start(5000);  // každých 5 s kontrola
}

void WatchdogWorker::stop() { timer_->stop(); }

void WatchdogWorker::onHeartbeat(const QString& name) { lastBeat_[name].restart(); }

void WatchdogWorker::check() {
    for (auto it = lastBeat_.cbegin(); it != lastBeat_.cend(); ++it) { 
        const QString& name = it.key();
        qint64 elapsed = it.value().elapsed();
        if (elapsed > timeoutMs_) {
            qWarning() << "[Watchdog] Worker" << name << "stall for" << elapsed << "ms";
            emit restartRequested(name);
        }
    }
}
