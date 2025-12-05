#pragma once

#include <QObject>
#include <QElapsedTimer>
#include <QHash>

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
    const qint64 timeoutMs_ = 25000;  // 20 s bez heartbeat → považujeme za zaseklé
};
