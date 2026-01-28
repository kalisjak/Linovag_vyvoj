#include "telemetryBuilder.hpp"

#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtGlobal>

static inline bool isInvalidValue(double v) { return qIsNaN(v) || v <= -30.0; }

static inline QJsonValue jsonTempOrDash(double v) { return isInvalidValue(v) ? QJsonValue(QStringLiteral("--")) : QJsonValue(v); }

QByteArray TelemetryBuilder::buildPayload(double v1, double v2, double v3, double v4, double v5, double v6,
                                          double hum, double targetTemp1, double targetTemp2, int swType) {
    const QString ts = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    QJsonObject data;

    if (swType == 3) {
        data["tempWell1"] = jsonTempOrDash(v1);
        data["tempEvap1"] = jsonTempOrDash(v3);
        data["tempCond"] = jsonTempOrDash(v5);
        data["tempIntake"] = jsonTempOrDash(v6);
        data["hum"] = jsonTempOrDash(hum);
        data["setTemp1"] = jsonTempOrDash(targetTemp1);
        data["ok"] = 1;
        data["status"] = QStringLiteral("online");

    } else {
        data["tempWell1"] = jsonTempOrDash(v1);
        data["tempWell2"] = jsonTempOrDash(v2);
        data["tempEvap1"] = jsonTempOrDash(v3);
        data["tempEvap2"] = jsonTempOrDash(v4);
        data["tempCond"] = jsonTempOrDash(v5);
        data["tempIntake"] = jsonTempOrDash(v6);
        data["hum"] = jsonTempOrDash(hum);
        data["setTemp1"] = jsonTempOrDash(targetTemp1);
        data["setTemp2"] = jsonTempOrDash(targetTemp2);

        data["ok"] = 1;
        data["status"] = QStringLiteral("online");
    }

    QJsonObject root;
    root["ts"] = ts;
    root["schema"] = QStringLiteral("v1");
    // root["serial"] = serial;
    root["data"] = data;

    return QJsonDocument(root).toJson(QJsonDocument::Compact);
}
