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

    // Heartbeat MQTT → watchdog (přidáme níže, až budeme mít watchdog)

    // ==================== Sensor worker + thread ====================
    QThread* sensorThread = new QThread(&app);
    SensorWorker* sensorWorker = new SensorWorker;

    sensorWorker->moveToThread(sensorThread);

    QObject::connect(sensorThread, &QThread::started, sensorWorker, &SensorWorker::start);

    // sensor -> backend
    QObject::connect(sensorWorker, &SensorWorker::sensorDS18, &backend, &Backend::updateTempValue, Qt::QueuedConnection);  // TODO
    QObject::connect(sensorWorker, &SensorWorker::sensorDHT22Value, &backend, &Backend::updateIntakeValue, Qt::QueuedConnection);  // TODO

    // backend -> sensor (forced ovládání)
    QObject::connect(&backend, &Backend::requestForcedEnabled, sensorWorker, &SensorWorker::setForcedEnabled, Qt::QueuedConnection);

    QObject::connect(&backend, &Backend::requestForcedTemps, sensorWorker, &SensorWorker::setForcedTemps, Qt::QueuedConnection);



    // ==================== Cooling worker + thread ====================
    // QThread* coolingThread = new QThread(&app);

    // CoolingWorker* coolingW1 = new CoolingWorker(AppConfig::COMPRESSOR1_PIN, AppConfig::FAN_PWM1_PIN, QStringLiteral("coolingW1"));

    // coolingW1->moveToThread(coolingThread);

    // QObject::connect(coolingThread, &QThread::started, coolingW1, &CoolingWorker::start);

    // // senzory → cooling (teperatures)
    // QObject::connect(sensorWorker, &SensorWorker::sensorDS18, coolingW1, &CoolingWorker::onTempSensors, Qt::QueuedConnection);

    // // targetTemp z backendu → cooling (přes lambda, protože signal nemá parametr)
    // QObject::connect(&backend, &Backend::targetTempChanged, [&backend, coolingW1]() {
    //     QMetaObject::invokeMethod(coolingW1, "onTargetTempChanged", Qt::QueuedConnection, Q_ARG(double, backend.targetTemp()));
    // });
    // // cooling → backend (aktualizace stavu chlazení)
    // QObject::connect(coolingW1, &CoolingWorker::coolingStateChanged, &backend, &Backend::updateCoolingState, Qt::QueuedConnection);

    // // Pro typ 2+2
    // CoolingWorker* coolingW2 = new CoolingWorker(AppConfig::COMPRESSOR2_PIN, AppConfig::FAN_PWM2_PIN, QStringLiteral("coolingW2"));
    // coolingW2->moveToThread(coolingThread);
    // QObject::connect(coolingThread, &QThread::started, coolingW2, &CoolingWorker::start);

    // TODO: napojeni coolingW2 (senzory, targetTemp, backend)

    // TODO: napojení na watchdog

    // ==================== Watchdog worker + thread ====================
    QThread* watchdogThread = new QThread(&app);
    WatchdogWorker* watchdog = new WatchdogWorker;

    watchdog->moveToThread(watchdogThread);

    QObject::connect(watchdogThread, &QThread::started, watchdog, &WatchdogWorker::start);

    // heartbeaty do watchdogu
    QObject::connect(sensorWorker, &SensorWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);

    // QObject::connect(coolingW1, &CoolingWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);

    QObject::connect(mqttWorker, &MqttWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat, Qt::QueuedConnection);

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
        // stopWorker(coolingW1, coolingThread, "stop", "Cooling");
        // stopWorker(coolingW2, coolingThread, "stop", "Cooling");
        stopWorker(watchdog, watchdogThread, "stop", "Watchdog");

        mqttWorker = nullptr;
        sensorWorker = nullptr;
        // coolingW1 = nullptr;
        // coolingW1 = nullptr;
        watchdog = nullptr;
        mqttThread = nullptr;
        sensorThread = nullptr;
        // coolingThread = nullptr;
        watchdogThread = nullptr;
    });

    // ----------------- Spuštění vláken -----------------
    mqttThread->start();
    sensorThread->start();
    // coolingThread->start();
    watchdogThread->start();

    return app.exec();
}
