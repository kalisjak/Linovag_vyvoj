#include "logManager.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QTextStream>

void LogManager::initLogs()
{
    QString basePath;
    if (basePath.isEmpty()) {
        basePath = QCoreApplication::applicationDirPath() + QStringLiteral("/..");
    }

    QDir dir(basePath);
    if (!dir.exists()) {
        dir.mkpath(QStringLiteral("."));
    }

    if (!dir.cd(QStringLiteral("logs"))) {
        dir.mkdir(QStringLiteral("logs"));
        dir.cd(QStringLiteral("logs"));
    }

    logsDirPath_ = dir.absolutePath();

    const QString pattern = QStringLiteral("temperature_log_*.txt");
    const QString prefix = QStringLiteral("temperature_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);

    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    if (!indexToFile.isEmpty()) {
        while (indexToFile.size() > kMaxLogFiles) {
            const int firstKey = indexToFile.firstKey();
            const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
            QFile::remove(oldFile);
            indexToFile.remove(firstKey);
        }

        currentLogIndex_ = indexToFile.lastKey();
        currentLogFilePath_ = dir.absoluteFilePath(indexToFile.last());
        historyLog_ = loadLastLines(currentLogFilePath_, kMaxHistoryLines);
    } else {
        currentLogIndex_ = 1;
        const QString fileName = QStringLiteral("temperature_log_%1.txt").arg(currentLogIndex_, 3, 10, QChar('0'));
        currentLogFilePath_ = dir.absoluteFilePath(fileName);
        historyLog_.clear();
    }

    initTempsLogs();
}

void LogManager::initTempsLogs()
{
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("alltemps_log_*.txt");
    const QString prefix = QStringLiteral("alltemps_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);
    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    if (!indexToFile.isEmpty()) {
        currentTempsLogIndex_ = indexToFile.lastKey();
        currentTempsLogFilePath_ = dir.absoluteFilePath(indexToFile.last());
    } else {
        currentTempsLogIndex_ = 1;
        const QString fileName = QStringLiteral("alltemps_log_%1.txt").arg(currentTempsLogIndex_, 3, 10, QChar('0'));
        currentTempsLogFilePath_ = dir.absoluteFilePath(fileName);
    }

    cleanupOldTempsLogFiles();
}

void LogManager::appendTempsLine(const QString& line)
{
    if (logsDirPath_.isEmpty()) initLogs();
    if (currentTempsLogFilePath_.isEmpty()) return;

    QFile file(currentTempsLogFilePath_);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << line << QLatin1Char('\n');
    }

    rotateTempsLogFileIfNeeded();
}

void LogManager::rotateTempsLogFileIfNeeded()
{
    if (currentTempsLogFilePath_.isEmpty()) return;

    QFileInfo info(currentTempsLogFilePath_);
    if (!info.exists()) return;
    if (info.size() < kMaxLogFileSizeBytes) return;

    QDir dir(logsDirPath_);
    ++currentTempsLogIndex_;
    const QString fileName = QStringLiteral("alltemps_log_%1.txt").arg(currentTempsLogIndex_, 3, 10, QChar('0'));
    currentTempsLogFilePath_ = dir.absoluteFilePath(fileName);

    cleanupOldTempsLogFiles();
}

void LogManager::cleanupOldTempsLogFiles()
{
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("alltemps_log_*.txt");
    const QString prefix = QStringLiteral("alltemps_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);
    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    while (indexToFile.size() > kMaxLogFiles) {
        const int firstKey = indexToFile.firstKey();
        const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
        QFile::remove(oldFile);
        indexToFile.remove(firstKey);
    }
}

QStringList LogManager::loadLastLines(const QString& filePath, int maxLines) const
{
    QStringList result;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return result;

    QTextStream in(&file);
    in.setCodec("UTF-8");
    const QString content = in.readAll();
    QStringList lines = content.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    if (lines.size() <= maxLines) {
        for (QString& l : lines) result.append(l.trimmed());
    } else {
        const int start = lines.size() - maxLines;
        for (int i = start; i < lines.size(); ++i) {
            result.append(lines.at(i).trimmed());
        }
    }

    return result;
}

void LogManager::appendHistoryLine(const QString& line)
{
    if (logsDirPath_.isEmpty()) initLogs();

    historyLog_.append(line);
    while (historyLog_.size() > kMaxHistoryLines) {
        historyLog_.removeFirst();
    }

    if (currentLogFilePath_.isEmpty()) return;

    QFile file(currentLogFilePath_);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << line << QLatin1Char('\n');
    }

    rotateLogFileIfNeeded();
}

void LogManager::rotateLogFileIfNeeded()
{
    if (currentLogFilePath_.isEmpty()) return;

    QFileInfo info(currentLogFilePath_);
    if (!info.exists()) return;
    if (info.size() < kMaxLogFileSizeBytes) return;

    QDir dir(logsDirPath_);
    ++currentLogIndex_;

    const QString fileName = QStringLiteral("temperature_log_%1.txt").arg(currentLogIndex_, 3, 10, QChar('0'));
    currentLogFilePath_ = dir.absoluteFilePath(fileName);

    cleanupOldLogFiles();
}

void LogManager::cleanupOldLogFiles()
{
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("temperature_log_*.txt");
    const QString prefix = QStringLiteral("temperature_log_");
    const QString suffix = QStringLiteral(".txt");

    QStringList files = dir.entryList(QStringList() << pattern, QDir::Files, QDir::Name);
    QMap<int, QString> indexToFile;
    for (const QString& fileName : files) {
        if (!fileName.startsWith(prefix) || !fileName.endsWith(suffix)) continue;

        const QString numberPart = fileName.mid(prefix.size(), fileName.size() - prefix.size() - suffix.size());
        bool ok = false;
        int idx = numberPart.toInt(&ok);
        if (!ok) continue;

        indexToFile[idx] = fileName;
    }

    while (indexToFile.size() > kMaxLogFiles) {
        const int firstKey = indexToFile.firstKey();
        const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
        QFile::remove(oldFile);
        indexToFile.remove(firstKey);
    }
}
