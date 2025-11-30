#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>

#include "backend.hpp"
#include "SensorWorker.hpp"
#include "MqttWorker.hpp"
#include "WatchdogWorker.hpp"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    Backend backend;

    // vlákna
    QThread sensorThread;
    QThread mqttThread;
    QThread watchdogThread;

    SensorWorker  sensorWorker;
    MqttWorker    mqttWorker;
    WatchdogWorker watchdog;

    sensorWorker.moveToThread(&sensorThread);
    mqttWorker.moveToThread(&mqttThread);
    watchdog.moveToThread(&watchdogThread);

    // start/stop
    QObject::connect(&sensorThread, &QThread::started,
                     &sensorWorker, &SensorWorker::start);
    QObject::connect(&mqttThread, &QThread::started,
                     &mqttWorker, &MqttWorker::start);
    QObject::connect(&watchdogThread, &QThread::started,
                     &watchdog, &WatchdogWorker::start);

    QObject::connect(&app, &QCoreApplication::aboutToQuit, [&](){
        sensorWorker.stop();
        mqttWorker.stop();
        watchdog.stop();

        sensorThread.quit();
        mqttThread.quit();
        watchdogThread.quit();

        sensorThread.wait();
        mqttThread.wait();
        watchdogThread.wait();
    });

    // propojení: senzory → backend
    QObject::connect(&sensorWorker, &SensorWorker::sensorValues,
                     &backend,      &Backend::onSensorValues);

    // heartbeat → watchdog
    QObject::connect(&sensorWorker, &SensorWorker::heartbeat,
                     &watchdog,     &WatchdogWorker::onHeartbeat);
    QObject::connect(&mqttWorker,   &MqttWorker::heartbeat,
                     &watchdog,     &WatchdogWorker::onHeartbeat);

    // backend → mqtt worker
    QObject::connect(&backend,    &Backend::publishMqtt,
                     &mqttWorker, &MqttWorker::publish);

    // mqtt worker → backend (stav připojení)
    QObject::connect(&mqttWorker, &MqttWorker::connectedChanged,
                     &backend,    &Backend::onMqttConnectedChanged);

    // TODO: watchdog → zatím jen log / do budoucna restart konkrétního workeru
    QObject::connect(&watchdog, &WatchdogWorker::restartRequested,
                     [&](const QString& name){
        qWarning() << "[Main] Restart requested for" << name;
        // tady můžeš později implementovat real restart specifického threadu
    });

    // QML
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qml/App.qml")));

    sensorThread.start();
    mqttThread.start();
    watchdogThread.start();

    return app.exec();
}
