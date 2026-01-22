#include "telemetryBuilder.hpp"

#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtGlobal>

static inline bool isInvalidValue(double v)
{
    return qIsNaN(v) || v <= -98.0;
}

static inline QJsonValue jsonTempOrDash(double v)
{
    return isInvalidValue(v) ? QJsonValue(QStringLiteral("--")) : QJsonValue(v);
}

bool TelemetryBuilder::isInvalid(double v)
{
    return isInvalidValue(v);
}

QByteArray TelemetryBuilder::buildV1(const QString& serial,
                                    double t1, double t2, double t3,
                                    double t4, double t5, double t6,
                                    double hum)
{
    const QString ts = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    QJsonObject data;
    data["t1"] = jsonTempOrDash(t1);
    data["t2"] = jsonTempOrDash(t2);
    data["t3"] = jsonTempOrDash(t3);
    data["t4"] = jsonTempOrDash(t4);
    data["t5"] = jsonTempOrDash(t5);
    data["t6"] = jsonTempOrDash(t6);
    data["hum"] = jsonTempOrDash(hum);

    QJsonObject root;
    root["ts"] = ts;
    root["schema"] = QStringLiteral("v1");
    root["serial"] = serial;
    root["data"] = data;

    return QJsonDocument(root).toJson(QJsonDocument::Compact);
}
