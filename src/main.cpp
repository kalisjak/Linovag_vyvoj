
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QByteArray>
#include <QString>
#include "backend.hpp"

// Pomocná: čtení bool z env
static bool envIsOn(const char* name) {
    const QByteArray v = qgetenv(name);
    const QByteArray l = v.toLower();
    return (!v.isEmpty() && (v == "1" || l == "true" || l == "yes" || v == "on"));
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 1) Detekce platformy + přepínače
    const QByteArray platform = qgetenv("QT_QPA_PLATFORM"); // "eglfs", "xcb", ...
    bool rotateScene = (platform == "eglfs");               // výchozí: otočit na RPi/eglfs

    // volitelný override z argumentu
    for (int i = 1; i < argc; ++i) {
        const QString a = QString::fromLocal8Bit(argv[i]);
        if (a == "--rotate")   rotateScene = true;
        if (a == "--norotate") rotateScene = false;
    }
    // override z proměnné prostředí (má přednost, pokud je nastavena)
    if (qEnvironmentVariableIsSet("PR_ROTATE"))
        rotateScene = envIsOn("PR_ROTATE");

    // 2) Tvůj backend
    Backend backend;

    // 3) QML engine + context properties
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("backend", &backend);
    engine.rootContext()->setContextProperty("rotateScene", rotateScene);

    // 4) Načtení App.qml z resource
    const QUrl url("qrc:/qml/App.qml");
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );
    engine.load(url);

    return app.exec();
}








// #include <QGuiApplication>
// #include <QQmlApplicationEngine>
// #include <QQmlContext>
// #include "backend.hpp"

// static bool envIsOn(const char* name) {
//     QByteArray v = qgetenv(name);
//     return (!v.isEmpty() && (v == "1" || v.toLower() == "true" || v.toLower() == "yes"));
// }

// int main(int argc, char *argv[])
// {
//     QGuiApplication app(argc, argv);

//     Backend backend;

//     QQmlApplicationEngine engine;
//     engine.rootContext()->setContextProperty("backend", &backend);

//     // const QUrl url = QUrl::fromLocalFile("qml/Main.qml");
//     const QUrl url = QUrl::fromLocalFile("qrc:/qml/App.qml");
//     QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app,
//                      [url](QObject *obj, const QUrl &objUrl) {
//                          if (!obj && url == objUrl)
//                              QCoreApplication::exit(-1);
//                      }, Qt::QueuedConnection);

//     engine.load(url);
//     return app.exec();
// }
