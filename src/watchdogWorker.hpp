#pragma once

#include <QObject>
#include <QElapsedTimer>
#include <QHash>

#include "config.hpp"

class QTimer;

class WatchdogWorker : public QObject {
    Q_OBJECT
public:
    explicit WatchdogWorker(QObject* parent = nullptr);

public slots:
    void start();
    void stop();
    void onHeartbeat(const QString& name);

signals:
    void restartRequested(const QString& name);

private slots:
    void check();

private:
    QTimer* timer_ = nullptr;
    QHash<QString, QElapsedTimer> lastBeat_;
    const qint64 checkTimeMs_ = AppConfig::WATCHDOG_CHECK_INTERVAL_MS;
    const qint64 timeoutMs_ = AppConfig::WATCHDOG_TIMEOUT_MS;
};
