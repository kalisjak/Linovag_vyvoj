#pragma once

#include <QByteArray>
#include <QString>

class TelemetryBuilder {
public:
    // Builds schema v1 payload:
    // {"ts": "<UTC ISO>", "schema":"v1", "serial":"...", "data": {t1..t6, hum}}
    // Invalid values (NaN or <= -98) are mapped to "--".
    static QByteArray buildV1(const QString& serial,
                             double t1, double t2, double t3,
                             double t4, double t5, double t6,
                             double hum);

private:
    static bool isInvalid(double v);
};
