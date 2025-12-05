#include <QDebug>
#include <QGuiApplication>
#include <QMetaObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>

#include "mqttWorker.hpp"
#include "sensorWorker.hpp"
#include "watchdogWorker.hpp"
#include "backend.hpp"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

    Backend backend;

    // --- ukazatele na vlákna / workery (budeme je restartovat) -------------
    QThread* sensorThread = nullptr;
    SensorWorker* sensorWorker = nullptr;

    QThread* mqttThread = nullptr;
    MqttWorker* mqttWorker = nullptr;

    QThread* watchdogThread = new QThread();
    WatchdogWorker* watchdog = new WatchdogWorker();

    // watchdog do vlastního vlákna
    watchdog->moveToThread(watchdogThread);
    QObject::connect(watchdogThread, &QThread::started, watchdog, &WatchdogWorker::start);

    // --- helper: zastavení a zničení senzorového vlákna --------------------
    auto stopSensor = [&]() {
        if (!sensorThread || !sensorWorker) return;

        qWarning() << "[Main] Stopping sensor worker/thread";

        // stop musí do jeho vlákna
        QMetaObject::invokeMethod(sensorWorker, "stop", Qt::QueuedConnection);

        sensorThread->quit();
        if (!sensorThread->wait(3000)) {
            qWarning() << "[Main] Sensor thread did not quit in time, terminating";
            sensorThread->terminate();  // poslední záchrana – ne moc hezká, ale lepší než zombie
            sensorThread->wait();
        }

        delete sensorWorker;
        delete sensorThread;

        sensorWorker = nullptr;
        sensorThread = nullptr;
    };

    // --- helper: zastavení a zničení mqtt vlákna ---------------------------
    auto stopMqtt = [&]() {
        if (!mqttThread) return;

        qWarning() << "[Main] Stopping MQTT worker/thread";

        if (mqttWorker) {
            // zavolá MqttWorker::stop() v jeho vlákně
            QMetaObject::invokeMethod(mqttWorker, "stop", Qt::BlockingQueuedConnection);
        }

        mqttThread->quit();

        if (!mqttThread->wait(3000)) {
            qWarning() << "[Main] MQTT thread did not quit in time, terminating";
            mqttThread->terminate();  // poslední záchrana
            mqttThread->wait();
        }

        // worker se smaže přes deleteLater napojený na finished
        mqttWorker = nullptr;

        delete mqttThread;
        mqttThread = nullptr;
    };

    // --- helper: vytvoření a nastartování senzorového vlákna --------------
    auto startSensor = [&]() {
        qWarning() << "[Main] Starting sensor worker/thread";

        sensorThread = new QThread();
        sensorWorker = new SensorWorker();

        sensorWorker->moveToThread(sensorThread);

        // start/stop
        QObject::connect(sensorThread, &QThread::started, sensorWorker, &SensorWorker::start);

        // senzory → backend
        QObject::connect(sensorWorker, &SensorWorker::sensorValues, &backend, &Backend::onSensorValues);

        // heartbeat → watchdog (jméno "sensors")
        QObject::connect(sensorWorker, &SensorWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat);

        sensorThread->start();
    };

    // --- helper: vytvoření a nastartování MQTT vlákna ----------------------
    auto startMqtt = [&]() {
        qWarning() << "[Main] Starting MQTT worker/thread";

        mqttThread = new QThread();
        mqttWorker = new MqttWorker();

        mqttWorker->moveToThread(mqttThread);

        // worker se smaže sám, AŽ thread skončí, a to ve "svém" vlákně
        QObject::connect(mqttThread, &QThread::finished, mqttWorker, &QObject::deleteLater);

        // start/stop
        QObject::connect(mqttThread, &QThread::started, mqttWorker, &MqttWorker::start);

        // backend → mqtt
        QObject::connect(&backend, &Backend::publishMqtt, mqttWorker, &MqttWorker::publish);

        // mqtt → backend (stav připojení)
        QObject::connect(mqttWorker, &MqttWorker::connectedChanged, &backend, &Backend::onMqttConnectedChanged);

        // heartbeat → watchdog
        QObject::connect(mqttWorker, &MqttWorker::heartbeat, watchdog, &WatchdogWorker::onHeartbeat);

        mqttThread->start();
    };

    // --- watchdog → restart konkrétního jádra ------------------------------
    QObject::connect(watchdog, &WatchdogWorker::restartRequested, [&](const QString& name) {
        qWarning() << "[Main] Restart requested for" << name;

        if (name == QLatin1String("sensors")) {
            stopSensor();
            startSensor();
        } else if (name == QLatin1String("mqtt")) {
            stopMqtt();
            startMqtt();
        } else {
            qWarning() << "[Main] Unknown worker name in watchdog:" << name;
        }
    });

    // --- QML engine --------------------------------------------------------
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qml/App.qml")));

    // --- start všech vláken ------------------------------------------------
    watchdogThread->start();
    startSensor();
    startMqtt();

    // --- korektní shutdown aplikace ----------------------------------------
    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&]() {
        // nejdřív periferie
        stopSensor();
        stopMqtt();

        // watchdog
        if (watchdog && watchdogThread) {
            QMetaObject::invokeMethod(watchdog, "stop", Qt::QueuedConnection);
            watchdogThread->quit();
            if (!watchdogThread->wait(3000)) {
                qWarning() << "[Main] Watchdog thread did not quit in time, terminating";
                watchdogThread->terminate();
                watchdogThread->wait();
            }
            delete watchdog;
            delete watchdogThread;
            watchdog = nullptr;
            watchdogThread = nullptr;
        }
    });

    return app.exec();
}
