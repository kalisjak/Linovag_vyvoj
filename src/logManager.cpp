#include "logManager.hpp"

#include <QCoreApplication>
#include <QDateTime>

namespace {

QString indexedFileName(const QString& prefix, int index) {
    return QStringLiteral("%1%2.txt").arg(prefix, QStringLiteral("%1").arg(index, 3, 10, QChar('0')));
}

QMap<int, QString> enumerateIndexedFiles(const QDir& dir, const QString& prefix) {
    const QString pattern = QStringLiteral("%1*.txt").arg(prefix);
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);

    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        const int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    return indexToFile;
}

}  // namespace

LogManager::LogManager(QObject* parent) : QObject(parent) {
    tempsTimer_ = new QTimer(this);
    tempsTimer_->setTimerType(Qt::CoarseTimer);
    connect(tempsTimer_, &QTimer::timeout, this, &LogManager::appendTempsSnapshotNow);
}

QString LogManager::ensureLogsDir(const QString& baseDirPath) {
    // If baseDirPath is empty, use app dir/..
    QString base = baseDirPath;
    if (base.isEmpty()) {
        base = QCoreApplication::applicationDirPath() + QStringLiteral("/..");
    }

    QDir dir(base);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }

    if (!dir.cd(QStringLiteral("logs"))) {
        dir.mkdir(QStringLiteral("logs"));
        dir.cd(QStringLiteral("logs"));
    }

    return dir.absolutePath();
}

void LogManager::init(const QString& baseDirPath) {
    logsDirPath_ = ensureLogsDir(baseDirPath);

    initFamily(QStringLiteral("temps_log_"), tempsFilePath_, tempsIndex_);
    initFamily(QStringLiteral("app_log_"), appFilePath_, appIndex_);

    // load last lines from temps log into history cache
    if (!tempsFilePath_.isEmpty()) {
        tempsHistory_ = loadLastLines(tempsFilePath_, kMaxHistoryLines);
        emit tempsHistoryChanged();
    }
}

void LogManager::setTempsSnapshotProvider(std::function<QString()> provider) {
    tempsSnapshotProvider_ = std::move(provider);
}

void LogManager::startTempsTimer(int intervalMs) {
    if (!tempsTimer_) return;
    tempsTimer_->setInterval(intervalMs);
    tempsTimer_->start();
}

void LogManager::stopTempsTimer() {
    if (tempsTimer_) tempsTimer_->stop();
}

void LogManager::appendTempsSnapshotNow() {
    if (!tempsSnapshotProvider_) return;

    const QString line = tempsSnapshotProvider_();
    if (line.isEmpty()) return;

    appendTempsLineCached(line);
    flushTempsIfNeeded();
}

void LogManager::appendAppLogLine(const QString& line) {
    if (logsDirPath_.isEmpty()) init(QString());

    const QString trimmed = line.trimmed();
    if (trimmed.isEmpty()) return;

    appCache_.append(trimmed);
    if (appCache_.size() >= kCacheLines) {
        flushCache(appCache_, appFilePath_);
        rotateIfNeeded(QStringLiteral("app_log_"), appFilePath_, appIndex_);
    }
}

void LogManager::initFamily(const QString& prefix, QString& filePath, int& index) {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    QMap<int, QString> indexToFile = enumerateIndexedFiles(dir, prefix);

    // trim oldest files above limit
    while (indexToFile.size() > kMaxFiles) {
        const int firstKey = indexToFile.firstKey();
        QFile::remove(dir.absoluteFilePath(indexToFile[firstKey]));
        indexToFile.remove(firstKey);
    }

    if (!indexToFile.isEmpty()) {
        index = indexToFile.lastKey();
        filePath = dir.absoluteFilePath(indexToFile.last());
    } else {
        index = 1;
        filePath = dir.absoluteFilePath(indexedFileName(prefix, index));
    }

    cleanupOldFiles(prefix);
}

void LogManager::rotateIfNeeded(const QString& prefix, QString& filePath, int& index) {
    if (filePath.isEmpty()) return;

    QFileInfo info(filePath);
    if (!info.exists()) return;
    if (info.size() < kMaxFileSizeBytes) return;

    QDir dir(logsDirPath_);
    ++index;
    filePath = dir.absoluteFilePath(indexedFileName(prefix, index));
    cleanupOldFiles(prefix);
}

void LogManager::cleanupOldFiles(const QString& prefix) {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    QMap<int, QString> indexToFile = enumerateIndexedFiles(dir, prefix);

    while (indexToFile.size() > kMaxFiles) {
        const int firstKey = indexToFile.firstKey();
        QFile::remove(dir.absoluteFilePath(indexToFile[firstKey]));
        indexToFile.remove(firstKey);
    }
}

void LogManager::flushCache(QStringList& cache, const QString& filePath) {
    if (filePath.isEmpty()) return;
    if (cache.isEmpty()) return;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        for (const QString& line : cache) {
            out << line << QLatin1Char('\n');
        }
    }
    cache.clear();
}

QStringList LogManager::loadLastLines(const QString& filePath, int maxLines) const {
    QStringList result;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return result;

    QTextStream in(&file);
    in.setCodec("UTF-8");
    const QString content = in.readAll();
    const QStringList lines = content.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    if (lines.size() <= maxLines) {
        for (const QString& l : lines) result.append(l.trimmed());
    } else {
        const int start = lines.size() - maxLines;
        for (int i = start; i < lines.size(); ++i) result.append(lines.at(i).trimmed());
    }

    return result;
}

void LogManager::appendTempsLineCached(const QString& line) {
    if (logsDirPath_.isEmpty()) init(QString());

    const QString trimmed = line.trimmed();
    if (trimmed.isEmpty()) return;

    tempsHistory_.append(trimmed);
    while (tempsHistory_.size() > kMaxHistoryLines) tempsHistory_.removeFirst();
    emit tempsHistoryChanged();

    tempsCache_.append(trimmed);
}

void LogManager::flushTempsIfNeeded() {
    if (tempsCache_.size() < kCacheLines) return;

    flushCache(tempsCache_, tempsFilePath_);
    rotateIfNeeded(QStringLiteral("temps_log_"), tempsFilePath_, tempsIndex_);
}
