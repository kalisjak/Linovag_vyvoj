#pragma once

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTextStream>
#include <QTimer>

#include <functional>

#include "config.hpp"

// LogManager:
//  - Temps log: one file family "temps_log_XXX.txt" + in-RAM cache exposed to QML via Backend::historyLog
//  - App log:   "app_log_XXX.txt" (general logs)
// Both logs:
//  - cache in RAM (append, flush in batches)
//  - rotation by max file size
//  - keep max number of files, delete oldest

class LogManager : public QObject {
    Q_OBJECT

   public:
    explicit LogManager(QObject* parent = nullptr);

    void init(const QString& baseDirPath);

    // Temps logging
    void setTempsSnapshotProvider(std::function<QString()> provider);
    void startTempsTimer(int intervalMs);
    void stopTempsTimer();
    void appendTempsSnapshotNow();

    // App logging (no timer)
    void appendAppLogLine(const QString& line);

    // Expose cached temps history for QML
    QStringList tempsHistory() const { return tempsHistory_; }

   signals:
    void tempsHistoryChanged();

   private:
    // dirs
    QString logsDirPath_;

    // temps log
    QString tempsFilePath_;
    int tempsIndex_ = 0;
    QStringList tempsHistory_;
    QStringList tempsCache_;
    std::function<QString()> tempsSnapshotProvider_;
    QTimer* tempsTimer_ = nullptr;

    // app log
    QString appFilePath_;
    int appIndex_ = 0;
    QStringList appCache_;

    // limits
    static constexpr int kCacheLines = AppConfig::LOG_CACHE_LINES;
    static constexpr int kMaxFiles = AppConfig::LOG_MAX_FILES;
    static constexpr long long kMaxFileSizeBytes = AppConfig::LOG_MAX_FILE_SIZE_BYTES;
    static constexpr int kMaxHistoryLines = AppConfig::LOG_MAX_HISTORY_LINES;

    // internals
    QString ensureLogsDir(const QString& baseDirPath);

    void initFamily(const QString& prefix, QString& filePath, int& index);
    void rotateIfNeeded(const QString& prefix, QString& filePath, int& index);
    void cleanupOldFiles(const QString& prefix);

    void flushCache(QStringList& cache, const QString& filePath);
    QStringList loadLastLines(const QString& filePath, int maxLines) const;

    void appendTempsLineCached(const QString& line);
    void flushTempsIfNeeded();
};
