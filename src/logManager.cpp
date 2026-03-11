#include "logManager.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QVector>

namespace {

struct ParsedTempsSnapshot {
    bool valid = false;
    QDateTime timestamp;
    QStringList keys;
    QVector<double> values;
};

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

QDateTime bucketStartFor(const QDateTime& ts) {
    const QDate date = ts.date();
    const QTime time = ts.time();
    const int bucketMinute = (time.minute() / AppConfig::TEMPS_LOG_AGGREGATION_MIN) * AppConfig::TEMPS_LOG_AGGREGATION_MIN;
    return QDateTime(date, QTime(time.hour(), bucketMinute), ts.timeSpec());
}

ParsedTempsSnapshot parseTempsSnapshot(const QString& line) {
    ParsedTempsSnapshot snapshot;
    const QString trimmed = line.trimmed();
    if (trimmed.isEmpty()) return snapshot;

    const int sepIdx = trimmed.indexOf(QStringLiteral(" - "));
    if (sepIdx <= 0) return snapshot;

    const QString tsText = trimmed.left(sepIdx).trimmed();
    const QString payload = trimmed.mid(sepIdx + 3).trimmed();
    const QDateTime ts = QDateTime::fromString(tsText, QStringLiteral("HH:mm dd.MM.yy"));
    if (!ts.isValid() || payload.isEmpty()) return snapshot;

    const QStringList parts = payload.split(QStringLiteral(", "), Qt::SkipEmptyParts);
    if (parts.isEmpty()) return snapshot;

    QStringList keys;
    QVector<double> values;
    keys.reserve(parts.size());
    values.reserve(parts.size());

    for (const QString& part : parts) {
        const int colonIdx = part.indexOf(QStringLiteral(": "));
        if (colonIdx <= 0) return ParsedTempsSnapshot{};

        bool ok = false;
        const QString key = part.left(colonIdx).trimmed();
        const double value = part.mid(colonIdx + 2).trimmed().toDouble(&ok);
        if (!ok || key.isEmpty()) return ParsedTempsSnapshot{};

        keys.append(key);
        values.append(value);
    }

    snapshot.valid = true;
    snapshot.timestamp = ts;
    snapshot.keys = keys;
    snapshot.values = values;
    return snapshot;
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

    consumeTempsSnapshot(line);
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

void LogManager::consumeTempsSnapshot(const QString& line) {
    const ParsedTempsSnapshot snapshot = parseTempsSnapshot(line);
    if (!snapshot.valid) return;

    const QDateTime bucketStart = bucketStartFor(snapshot.timestamp);

    if (!tempsBucket_.active) {
        tempsBucket_.active = true;
        tempsBucket_.bucketStart = bucketStart;
        tempsBucket_.lastTimestamp = snapshot.timestamp;
        tempsBucket_.keys = snapshot.keys;
        tempsBucket_.sums = snapshot.values;
        tempsBucket_.sampleCount = 1;
        return;
    }

    const bool sameBucket = tempsBucket_.bucketStart == bucketStart;
    const bool sameShape = tempsBucket_.keys == snapshot.keys && tempsBucket_.sums.size() == snapshot.values.size();

    if (!sameBucket || !sameShape) {
        flushCompletedTempsBucket();
        tempsBucket_.active = true;
        tempsBucket_.bucketStart = bucketStart;
        tempsBucket_.lastTimestamp = snapshot.timestamp;
        tempsBucket_.keys = snapshot.keys;
        tempsBucket_.sums = snapshot.values;
        tempsBucket_.sampleCount = 1;
        return;
    }

    tempsBucket_.lastTimestamp = snapshot.timestamp;
    ++tempsBucket_.sampleCount;
    for (int i = 0; i < tempsBucket_.sums.size(); ++i) {
        tempsBucket_.sums[i] += snapshot.values[i];
    }
}

void LogManager::flushCompletedTempsBucket() {
    if (!tempsBucket_.active || tempsBucket_.sampleCount <= 0 || tempsBucket_.keys.size() != tempsBucket_.sums.size()) {
        tempsBucket_ = TempsBucket{};
        return;
    }

    QStringList values;
    values.reserve(tempsBucket_.keys.size());
    for (int i = 0; i < tempsBucket_.keys.size(); ++i) {
        const double avg = tempsBucket_.sums[i] / static_cast<double>(tempsBucket_.sampleCount);
        values.append(QStringLiteral("%1: %2").arg(tempsBucket_.keys[i], QString::number(avg, 'f', 1)));
    }

    const QString line = QStringLiteral("%1 - %2")
                             .arg(tempsBucket_.lastTimestamp.toString(QStringLiteral("HH:mm dd.MM.yy")),
                                  values.join(QStringLiteral(", ")));
    appendTempsLineCached(line);
    flushTempsIfNeeded();

    tempsBucket_ = TempsBucket{};
}
