#include <QDebug>
#include <QGuiApplication>
#include <QMetaObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>

#include "backend.hpp"
#include "mqttWorker.hpp"
#include "sensorWorker.hpp"
#include "coolingWorker.hpp"
#include "watchdogWorker.hpp"

int main(int argc, char* argv[])
{

    QGuiApplication::setAttribute(Qt::AA_DisableHighDpiScaling); // disable high-DPI scaling
    QGuiApplication app(argc, argv);

    // ----------------- Backend + QML engine -----------------
    Backend backend;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qml/App.qml")));
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "[Main] Failed to load QML";
        return -1;
    }

    // ----------------- MQTT worker + thread -----------------
    QThread* mqttThread = new QThread(&app);
    MqttWorker* mqttWorker = new MqttWorker;

    mqttWorker->moveToThread(mqttThread);

    QObject::connect(mqttThread, &QThread::started,
                     mqttWorker, &MqttWorker::start);

    // Backend → MQTT (odesílání JSON payloadu)
    QObject::connect(&backend, &Backend::publishMqtt,
                     mqttWorker, &MqttWorker::publish,
                     Qt::QueuedConnection);

    // MQTT → Backend (info o připojení)
    QObject::connect(mqttWorker, &MqttWorker::connectedChanged,
                     &backend, &Backend::onMqttConnectedChanged,
                     Qt::QueuedConnection);

    // Heartbeat MQTT → watchdog (přidáme níže, až budeme mít watchdog)

    // ----------------- Sensor worker + thread -----------------
    QThread* sensorThread = new QThread(&app);
    SensorWorker* sensorWorker = new SensorWorker;

    sensorWorker->moveToThread(sensorThread);

    QObject::connect(sensorThread, &QThread::started,
                     sensorWorker, &SensorWorker::start);

    // senzory → backend (vnitřní teploty)
    QObject::connect(sensorWorker, &SensorWorker::sensorValues,
                     &backend, &Backend::onSensorValues,
                     Qt::QueuedConnection);

    // ----------------- Cooling worker + thread -----------------
    QThread* coolingThread = new QThread(&app);
    CoolingWorker* coolingWorker = new CoolingWorker;

    coolingWorker->moveToThread(coolingThread);

    QObject::connect(coolingThread, &QThread::started,
                     coolingWorker, &CoolingWorker::start);

    // senzory → cooling (průměr vnitřních teplot)
    QObject::connect(sensorWorker, &SensorWorker::sensorValues,
                     coolingWorker, &CoolingWorker::onTempSensors,
                     Qt::QueuedConnection);

    // výparník → cooling (defrost logika)
    QObject::connect(sensorWorker, &SensorWorker::evapValue,
                     coolingWorker, &CoolingWorker::onEvapTemp,
                     Qt::QueuedConnection);

    // targetTemp z backendu → cooling (přes lambda, protože signal nemá parametr)
    QObject::connect(&backend, &Backend::targetTempChanged,
                     [&backend, coolingWorker]() {
                         QMetaObject::invokeMethod(
                             coolingWorker,
                             "onTargetTempChanged",
                             Qt::QueuedConnection,
                             Q_ARG(double, backend.targetTemp()));
                     });

    // cooling → backend (aktualizace stavu chlazení)
    QObject::connect(coolingWorker, &CoolingWorker::coolingStateChanged,
                     &backend,       &Backend::updateCoolingState,
                     Qt::QueuedConnection);

    // ----------------- Watchdog worker + thread -----------------
    QThread* watchdogThread = new QThread(&app);
    WatchdogWorker* watchdog = new WatchdogWorker;

    watchdog->moveToThread(watchdogThread);

    QObject::connect(watchdogThread, &QThread::started,
                     watchdog, &WatchdogWorker::start);

    // heartbeaty do watchdogu
    QObject::connect(sensorWorker, &SensorWorker::heartbeat,
                     watchdog, &WatchdogWorker::onHeartbeat,
                     Qt::QueuedConnection);

    QObject::connect(coolingWorker, &CoolingWorker::heartbeat,
                     watchdog, &WatchdogWorker::onHeartbeat,
                     Qt::QueuedConnection);

    QObject::connect(mqttWorker, &MqttWorker::heartbeat,
                     watchdog, &WatchdogWorker::onHeartbeat,
                     Qt::QueuedConnection);

    // watchdog zatím jen loguje, co chce restartovat
    QObject::connect(watchdog, &WatchdogWorker::restartRequested,
                     [](const QString& name) {
                         qWarning() << "[Main] Watchdog requested restart of worker" << name
                                    << "(restart logic not implemented yet)";
                     });

    // ----------------- Korektní ukončení při exit -----------------
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&]() {
        qInfo() << "[Main] aboutToQuit – stopping workers";

        auto stopWorker = [](QObject* worker, QThread* thread,
                             const char* stopSlot, const char* name) {
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

        stopWorker(mqttWorker,    mqttThread,    "stop", "MQTT");
        stopWorker(sensorWorker,  sensorThread,  "stop", "Sensor");
        stopWorker(coolingWorker, coolingThread, "stop", "Cooling");
        stopWorker(watchdog,      watchdogThread,"stop", "Watchdog");

        mqttWorker    = nullptr;
        sensorWorker  = nullptr;
        coolingWorker = nullptr;
        watchdog      = nullptr;
        mqttThread    = nullptr;
        sensorThread  = nullptr;
        coolingThread = nullptr;
        watchdogThread= nullptr;
    });

    // ----------------- Spuštění vláken -----------------
    mqttThread->start();
    sensorThread->start();
    coolingThread->start();
    watchdogThread->start();

    return app.exec();
}
