#include <QCursor>
#include <QDebug>
#include <QGuiApplication>
#include <QMetaObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>

#include "backend.hpp"
#include "coolingWorker.hpp"
#include "mqttWorker.hpp"
#include "sensorWorker.hpp"
#include "watchdogWorker.hpp"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

#ifdef LNVG_USE_PIGPIO
    app.setOverrideCursor(Qt::BlankCursor);
#else
    // simulace – s kurzorem
#endif

    // ----------------- Backend + QML engine -----------------
    Backend backend;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qml/App.qml")));
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "[Main] Failed to load QML";
        return -1;
    }

    // ===================== MQTT worker + thread =====================
    QThread* mqttThread = new QThread(&app);
    MqttWorker* mqttWorker = new MqttWorker;

    mqttWorker->moveToThread(mqttThread);
    QObject::connect(mqttThread, &QThread::started, mqttWorker, &MqttWorker::start);

    // Backend → MQTT (odesílání JSON payloadu)
    QObject::connect(&backend, &Backend::publishMqtt, mqttWorker, &MqttWorker::publish, Qt::QueuedConnection);

    // MQTT → Backend (info o připojení)
    QObject::connect(mqttWorker, &MqttWorker::connectedChanged, &backend, &Backend::updateMqttConnected, Qt::QueuedConnection);

    // ==================== Sensor worker + thread ====================
    QThread* sensorThread = new QThread(&app);
    SensorWorker* sensorWorker = new SensorWorker;

    sensorWorker->moveToThread(sensorThread);
    QObject::connect(sensorThread, &QThread::started, sensorWorker, &SensorWorker::start);

    // sensor -> backend
    QObject::connect(sensorWorker, &SensorWorker::sensorDS18, &backend, &Backend::updateTempValue, Qt::QueuedConnection);
    QObject::connect(sensorWorker, &SensorWorker::sensorDHT22Value, &backend, &Backend::updateIntakeValue, Qt::QueuedConnection);

    // backend -> sensor (forced ovládání)
    QObject::connect(&backend, &Backend::requestForcedEnabled, sensorWorker, &SensorWorker::setForcedEnabled, Qt::QueuedConnection);
    QObject::connect(&backend, &Backend::requestForcedTemps, sensorWorker, &SensorWorker::setForcedTemps, Qt::QueuedConnection);

    // ==================== Cooling workers + threads ====================
    QThread* coolingThread1 = nullptr;
    QThread* coolingThread2 = nullptr;
    CoolingWorker* coolingW1 = nullptr;
    CoolingWorker* coolingW2 = nullptr;

    const int swTypeNow = backend.softwareType();

    if (swTypeNow == 3) {
        coolingThread1 = new QThread(&app);
        coolingW1 = new CoolingWorker(AppConfig::COMPRESSOR1_PIN,
                                      AppConfig::FAN_PWM1_PIN,
                                      1,
                                      3,
                                      QStringLiteral("cooling1"));
        coolingW1->moveToThread(coolingThread1);
        QObject::connect(coolingThread1, &QThread::started, coolingW1, &CoolingWorker::start);

        // senzory → cooling1
        QObject::connect(sensorWorker, &SensorWorker::sensorDS18, coolingW1, &CoolingWorker::onTempSensors, Qt::QueuedConnection);

        // target1 → cooling1
        QObject::connect(&backend, &Backend::targetTempChanged, [&backend, coolingW1]() {
            QMetaObject::invokeMethod(coolingW1, "onTargetTempChanged", Qt::QueuedConnection, Q_ARG(double, backend.targetTemp()));
        });

        // cooling1 → backend
        QObject::connect(coolingW1, &CoolingWorker::coolingStateChanged, &backend, &Backend::updateCoolingState, Qt::QueuedConnection);
    } else if (swTypeNow == 22) {
        // Cooling 1
        coolingThread1 = new QThread(&app);
        coolingW1 = new CoolingWorker(AppConfig::COMPRESSOR1_PIN,
                                      AppConfig::FAN_PWM1_PIN,
                                      1,
                                      3,
                                      QStringLiteral("cooling1"));
        coolingW1->moveToThread(coolingThread1);
        QObject::connect(coolingThread1, &QThread::started, coolingW1, &CoolingWorker::start);
        QObject::connect(sensorWorker, &SensorWorker::sensorDS18, coolingW1, &CoolingWorker::onTempSensors, Qt::QueuedConnection);
        QObject::connect(&backend, &Backend::targetTempChanged, [&backend, coolingW1]() {
            QMetaObject::invokeMethod(coolingW1, "onTargetTempChanged", Qt::QueuedConnection, Q_ARG(double, backend.targetTemp()));
        });
        QObject::connect(coolingW1, &CoolingWorker::coolingStateChanged, &backend, &Backend::updateCoolingState, Qt::QueuedConnection);

        // Cooling 2 (independent thread)
        coolingThread2 = new QThread(&app);
        coolingW2 = new CoolingWorker(AppConfig::COMPRESSOR2_PIN,
                                      AppConfig::FAN_PWM2_PIN,
                                      2,
                                      4,
                                      QStringLiteral("cooling2"));
        coolingW2->moveToThread(coolingThread2);
        QObject::connect(coolingThread2, &QThread::started, coolingW2, &CoolingWorker::start);
        QObject::connect(sensorWorker, &SensorWorker::sensorDS18, coolingW2, &CoolingWorker::onTempSensors, Qt::QueuedConnection);
        QObject::connect(&backend, &Backend::targetTemp2Changed, [&backend, coolingW2]() {
            QMetaObject::invokeMethod(coolingW2, "onTargetTempChanged", Qt::QueuedConnection, Q_ARG(double, backend.targetTemp2()));
        });
        QObject::connect(coolingW2, &CoolingWorker::coolingStateChanged, &backend, &Backend::updateCoolingState2, Qt::QueuedConnection);
    }

    // ==================== Watchdog worker + thread ====================
    QThread* watchdogThread = new QThread(&app);
    WatchdogWorker* watchdog = new WatchdogWorker;

    watchdog->moveToThread(watchdogThread);
    QObject::connect(watchdogThread, &QThread::started, watchdog, &WatchdogWorker::start);

    // heartbeaty do watchdogu
    QObject::connect(sensorWorker, &SensorWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);
    QObject::connect(mqttWorker, &MqttWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);

    if (coolingW1) {
        QObject::connect(coolingW1, &CoolingWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);
    }
    if (coolingW2) {
        QObject::connect(coolingW2, &CoolingWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);
    }

    // watchdog zatím jen loguje, co chce restartovat
    QObject::connect(watchdog, &WatchdogWorker::restartRequested, [](const QString& name) {
        qWarning() << "[Main] Watchdog requested restart of worker" << name << "(restart logic not implemented yet)";
    });

    // ==================== Korektní ukončení při exit ====================
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&]() {
        qInfo() << "[Main] aboutToQuit – stopping workers";

        auto stopWorker = [](QObject* worker, QThread* thread, const char* stopSlot, const char* name) {
            if (!thread) return;

            qInfo() << "[Main] Stopping" << name;

            if (worker) {
                QMetaObject::invokeMethod(worker, stopSlot, Qt::QueuedConnection);
            }

            thread->quit();
            if (!thread->wait(3000)) {
                qWarning() << "[Main]" << name << "thread did not quit in time, terminating";
                thread->terminate();
                thread->wait();
            }

            delete worker;
            delete thread;
        };

        stopWorker(mqttWorker, mqttThread, "stop", "MQTT");
        stopWorker(sensorWorker, sensorThread, "stop", "Sensor");
        stopWorker(coolingW1, coolingThread1, "stop", "Cooling1");
        stopWorker(coolingW2, coolingThread2, "stop", "Cooling2");
        stopWorker(watchdog, watchdogThread, "stop", "Watchdog");

        mqttWorker = nullptr;
        sensorWorker = nullptr;
        coolingW1 = nullptr;
        coolingW2 = nullptr;
        watchdog = nullptr;

        mqttThread = nullptr;
        sensorThread = nullptr;
        coolingThread1 = nullptr;
        coolingThread2 = nullptr;
        watchdogThread = nullptr;
    });

    // ----------------- Spuštění vláken -----------------
    mqttThread->start();
    sensorThread->start();
    if (coolingThread1) coolingThread1->start();
    if (coolingThread2) coolingThread2->start();
    watchdogThread->start();

    return app.exec();
}
