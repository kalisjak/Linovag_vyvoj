#pragma once

#include <QString>
#include <QStringList>

#include "config.hpp"

class LogManager {
public:
    LogManager() = default;

    void initLogs();
    void initTempsLogs();

    void appendHistoryLine(const QString& line);
    void appendTempsLine(const QString& line);

    QStringList historyCache() const { return historyLog_; }

private:
    QStringList historyLog_;

    QString logsDirPath_;
    QString currentLogFilePath_;
    int currentLogIndex_ = 0;

    QString currentTempsLogFilePath_;
    int currentTempsLogIndex_ = 0;

    static constexpr int kMaxHistoryLines = AppConfig::LOG_MAX_HISTORY_LINES;
    static constexpr int kMaxLogFiles = AppConfig::LOG_MAX_FILES;
    static constexpr long long kMaxLogFileSizeBytes = AppConfig::LOG_MAX_FILE_SIZE_BYTES;

    void rotateLogFileIfNeeded();
    void rotateTempsLogFileIfNeeded();
    void cleanupOldLogFiles();
    void cleanupOldTempsLogFiles();

    QStringList loadLastLines(const QString& filePath, int maxLines) const;
};
