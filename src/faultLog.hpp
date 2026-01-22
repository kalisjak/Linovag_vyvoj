#pragma once

#include <QHash>
#include <QString>
#include <QStringList>

class FaultLog {
public:
    // When switching to active==true from false, appends a timestamped line.
    void setActive(const QString& key, bool active, const QString& msg);

    QStringList historyLines() const { return historyLines_; }
    bool anyActive() const { return anyActive_; }

private:
    QHash<QString, bool> activeMap_;
    QStringList historyLines_;
    bool anyActive_ = false;

    void recomputeAnyActive();
};
