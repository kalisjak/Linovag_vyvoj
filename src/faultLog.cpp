#include "faultLog.hpp"

#include <QDateTime>

void FaultLog::recomputeAnyActive()
{
    anyActive_ = false;
    for (auto it = activeMap_.constBegin(); it != activeMap_.constEnd(); ++it) {
        if (it.value()) { anyActive_ = true; break; }
    }
}

void FaultLog::setActive(const QString& key, bool active, const QString& msg)
{
    const bool prev = activeMap_.value(key, false);
    activeMap_.insert(key, active);

    if (!prev && active) {
        const QString ts = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm dd.MM.yy"));
        historyLines_.append(QStringLiteral("%1 - %2").arg(ts, msg));
        // keep it bounded-ish
        while (historyLines_.size() > 500) historyLines_.removeFirst();
    }

    recomputeAnyActive();
}
