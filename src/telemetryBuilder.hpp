#pragma once

#include <QByteArray>
#include <QString>

class TelemetryBuilder {
public:
    // {"ts": "<UTC ISO>", "schema":"v1", "serial":"...", "data": {...}}
    static QByteArray buildPayload(
                              double v1, double v2, double v3,
                              double v4, double v5, double v6,
                              double hum, double targetTemp1,
                              double targetTemp2,
                              int swType);

private:
    static bool isInvalid(double v);
};
