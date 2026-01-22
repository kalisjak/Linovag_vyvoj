#pragma once

#include <QObject>

class PowerWorker : public QObject {
    Q_OBJECT
public:
    explicit PowerWorker(int power1Pin = -1, int power2Pin = -1, QObject* parent = nullptr);
    ~PowerWorker();

public slots:
    void setPower1(bool on);
    void setPower2(bool on);

private:
    const int power1Pin_;
    const int power2Pin_;
    bool hwInitialized_ = false;

    void initGpio();
    void shutdownGpio();
    void writePin(int pin, bool on);
};
