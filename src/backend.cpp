#include "backend.hpp"
#include "runtimeConfig.hpp"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QSslCertificate>
#include <QSslConfiguration>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>

Backend::Backend(QObject* parent) : QObject(parent), rng_(std::random_device{}()) {
    mqttTimer_ = new QTimer(this);
    mqttTimer_->setInterval(mqtt_push_time);  // 60 s
    connect(mqttTimer_, &QTimer::timeout,
            this, &Backend::onMqttTimerTick);
    mqttTimer_->start();

    initLogs();
}

// --- Slot pro změnu požadované teploty z QML -------------------------------

void Backend::setTargetTemp(double t) {
    if (targetTemp_ == t) return;

    targetTemp_ = t;
    // qInfo() << "[Backend] Target temperature set to" << targetTemp_ << "°C";
    emit targetTempChanged();
}

// --- Forced setters ------------------------------------------

void Backend::setForcedSensors(bool en)
{
    if (forcedSensors_ == en) return;
    forcedSensors_ = en;
    emit forcedSensorsChanged();
    emit requestForcedEnabled(forcedSensors_);
}

void Backend::setForcedTemp1(double v)
{
    if (qFuzzyCompare(forcedT1_, v)) return;
    forcedT1_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp2(double v)
{
    if (qFuzzyCompare(forcedT2_, v)) return;
    forcedT2_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp3(double v)
{
    if (qFuzzyCompare(forcedT3_, v)) return;
    forcedT3_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp4(double v)
{
    if (qFuzzyCompare(forcedT4_, v)) return;
    forcedT4_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}

void Backend::setForcedTemp5(double v)
{
    if (qFuzzyCompare(forcedT5_, v)) return;
    forcedT5_ = v;
    emit forcedTempsChanged();
    emit requestForcedTemps(forcedT1_, forcedT2_, forcedT3_, forcedT4_, forcedT5_);
}
// --- Sloty volané z worker vláken -----------------------------------------

void Backend::onSensorValues(double v1, double v2) {
    bool changed1 = false;
    bool changed2 = false;

    if (value1_ != v1) {
        value1_ = v1;
        changed1 = true;
        emit value1Changed();
    }

    if (value2_ != v2) {
        value2_ = v2;
        changed2 = true;
        emit value2Changed();
    }

    QDateTime now = QDateTime::currentDateTime();
    // formát: "16:00 03.11.25 - Internal temp 3.4°C"
    const QString line =
        QStringLiteral("%1 - Internal temp %2%3C").arg(now.toString("HH:mm dd.MM.yy"), QString::number(v2, 'f', 1), QString::fromUtf8("°"));

    appendLogLine(line);
    appendAllTempsSnapshot();
}

void Backend::onSensorValues45(double v4, double v5)
{
    updateSensorValues45(v4, v5);
}

void Backend::updateSensorValues(double v1, double v2)
{
    if (!qFuzzyCompare(value1_, v1)) { value1_ = v1; emit value1Changed(); }
    if (!qFuzzyCompare(value2_, v2)) { value2_ = v2; emit value2Changed(); }
}

void Backend::updateSensorValues45(double v4, double v5)
{
    if (!qFuzzyCompare(value4_, v4)) { value4_ = v4; emit value4Changed(); }
    if (!qFuzzyCompare(value5_, v5)) { value5_ = v5; emit value5Changed(); }
    appendAllTempsSnapshot();
}

void Backend::updateEvapValue(double v3)
{
    if (qFuzzyCompare(value3_, v3)) return;
    value3_ = v3;
    emit value3Changed();
    appendAllTempsSnapshot();
}


void Backend::onMqttConnectedChanged(bool ok) {
    if (mqttConnected_ == ok) return;

    mqttConnected_ = ok;
    emit mqttConnectedChanged();
}

// --- Aktualizace stavů chlazení ---------------------------------------------
QString Backend::reclaimOrderNumber() const
{
    return RuntimeConfig::reclaimOrderNumber();
}

QString Backend::reclaimEmail() const
{
    return RuntimeConfig::reclaimEmail();
}

void Backend::setReclaimOrderNumber(const QString& number)
{
    RuntimeConfig::setReclaimOrderNumber(number);
    emit reclaimInfoChanged();
}

void Backend::setReclaimEmail(const QString& email)
{
    RuntimeConfig::setReclaimEmail(email);
    emit reclaimInfoChanged();
}

void Backend::updateCoolingState(bool coolingActive,
                                 bool defrostActive,
                                 bool compressorOn)
{
    if (coolingActive_ != coolingActive) {
        coolingActive_ = coolingActive;
        emit coolingActiveChanged();
    }

    if (defrostActive_ != defrostActive) {
        defrostActive_ = defrostActive;
        emit defrostActiveChanged();
    }

    if (compressorOn_ != compressorOn) {
        compressorOn_ = compressorOn;
        emit compressorOnChanged();
    }
}

void Backend::setErrorActive(bool active)
{
    if (errorActive_ == active)
        return;

    errorActive_ = active;
    emit errorActiveChanged();
}


// --- Odesílání MQTT zpráv (přes MqttWorker) --------------------------------

void Backend::sendMessage(const QString& msg) {
    bool ok = false;
    const double temp = msg.toDouble(&ok);
    if (!ok) {
        qWarning() << "[Backend] sendMessage: invalid temperature value:" << msg;
        return;
    }

    const QString ts = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    const QString payloadStr = QString::fromLatin1(
                                   "{"
                                   "\"ts\":\"%1\","
                                   "\"schema\":\"v1\","
                                   "\"data\":{"
                                   "\"temp1\":%2,"
                                   "\"temp2\":2.3,"
                                   "\"ok\":1,"
                                   "\"status\":\"online\""
                                   "}"
                                   "}")
                                   .arg(ts)
                                   .arg(temp, 0, 'f', 2);

    const QByteArray payload = payloadStr.toUtf8();

    qInfo().noquote() << "[Backend] Prepared payload"; // << payload;

    // Reálné odesílání necháváme na MqttWorkeru v jiném vlákně
    emit publishMqtt(payload);
}

void Backend::onMqttTimerTick() 
{
    sendMessage(QString::number(value2_));
}

// --- Logování teplot do souborů + bufferu ----------------------------------

void Backend::initLogs() {
    // Základní adresář pro logy je adresář aplikace + "/logs".
    QString basePath = ""; //QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (basePath.isEmpty()) {
        basePath = QCoreApplication::applicationDirPath() + QStringLiteral("/..");
        // qInfo() << "[Backend] Logs is in " << basePath << "hej tady to hledej";
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
        // smaž staré logy, pokud jich je víc než limit
        while (indexToFile.size() > kMaxLogFiles) {
            const int firstKey = indexToFile.firstKey();
            const QString oldFile = dir.absoluteFilePath(indexToFile[firstKey]);
            QFile::remove(oldFile);
            indexToFile.remove(firstKey);
        }

        currentLogIndex_ = indexToFile.lastKey();
        currentLogFilePath_ = dir.absoluteFilePath(indexToFile.last());
        historyLog_ = loadLastLines(currentLogFilePath_, kMaxHistoryLines);
        emit historyLogChanged();
    } else {
        // žádný log ještě není – začneme od 1
        currentLogIndex_ = 1;
        const QString fileName = QStringLiteral("temperature_log_%1.txt").arg(currentLogIndex_, 3, 10, QChar('0'));
        currentLogFilePath_ = dir.absoluteFilePath(fileName);
        historyLog_.clear();
        emit historyLogChanged();
    }
    initTempsLogs();
}
void Backend::initTempsLogs() {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("alltemps_log_*.txt");
    const QString prefix  = QStringLiteral("alltemps_log_");
    const QString suffix  = QStringLiteral(".txt");

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

void Backend::appendTempsLogLine(const QString& line) {
    if (logsDirPath_.isEmpty()) {
        initLogs();
    }
    if (currentTempsLogFilePath_.isEmpty()) return;

    QFile file(currentTempsLogFilePath_);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << line << QLatin1Char('\n');
    }

    rotateTempsLogFileIfNeeded();
}

void Backend::rotateTempsLogFileIfNeeded() {
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

void Backend::cleanupOldTempsLogFiles() {
    if (logsDirPath_.isEmpty()) return;

    QDir dir(logsDirPath_);
    const QString pattern = QStringLiteral("alltemps_log_*.txt");
    const QString prefix  = QStringLiteral("alltemps_log_");
    const QString suffix  = QStringLiteral(".txt");

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

void Backend::appendAllTempsSnapshot()
{
    // formát: "16:00 03.11.25 - target: x, vana-t1: x, vana-t2: x, vypar: x, t4: x, t5: x"
    const QDateTime now = QDateTime::currentDateTime();

    const QString line = QStringLiteral(
        "%1 - target: %2, vana-t1: %3, vana-t2: %4, vypar: %5, kondenz: %6, nasavani: %7")
        .arg(
            now.toString(QStringLiteral("HH:mm dd.MM.yy")),
            QString::number(targetTemp_, 'f', 1),
            QString::number(value1_, 'f', 1),
            QString::number(value2_, 'f', 1),
            QString::number(value3_, 'f', 1),
            QString::number(value4_, 'f', 1),
            QString::number(value5_, 'f', 1)
        );

    appendTempsLogLine(line);
}

QStringList Backend::loadLastLines(const QString& filePath, int maxLines) const {
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

void Backend::appendLogLine(const QString& line) {
    if (logsDirPath_.isEmpty()) {
        initLogs();
    }

    historyLog_.append(line);
    while (historyLog_.size() > kMaxHistoryLines) {
        historyLog_.removeFirst();
    }
    emit historyLogChanged();

    if (currentLogFilePath_.isEmpty()) return;

    QFile file(currentLogFilePath_);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&file);
        out.setCodec("UTF-8");
        out << line << QLatin1Char('\n');
    }

    rotateLogFileIfNeeded();
}

void Backend::rotateLogFileIfNeeded() {
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

void Backend::cleanupOldLogFiles() {
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

QString Backend::serialNumber() const {
    return QStringLiteral("SN-65468");
    //return RuntimeConfig::deviceSerial();
}