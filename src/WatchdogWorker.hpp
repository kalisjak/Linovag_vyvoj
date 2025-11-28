#pragma once
#include <QObject>
#include <QHash>
#include <QElapsedTimer>

class QTimer;

class WatchdogWorker : public QObject {
    Q_OBJECT
public:
    explicit WatchdogWorker(QObject* parent = nullptr);

signals:
    void restartRequested(const QString& name);

public slots:
    void start();
    void stop();
    void onHeartbeat(const QString& name);

private slots:
    void check();

private:
    QTimer* timer_ = nullptr;
    QHash<QString, QElapsedTimer> lastBeat_;
    int timeoutMs_ = 15000; // 15 s bez hearbeatu = mrtvo
};
