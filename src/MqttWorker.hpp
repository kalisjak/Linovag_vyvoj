#pragma once
#include <QObject>
#include <QQueue>

class QMqttClient;
class QTimer;

/**
 * @brief MqttWorker
 *
 * Běží v samostatném vlákně (viz main.cpp).
 * - Přijímá požadavky z Backend přes slot publish(const QByteArray&).
 * - Zprávy si ukládá do vnitřního bufferu (fronta).
 * - Každých 20 s se timerem pokusí:
 *      * znovu připojit k MQTT brokeru (když není připojeno),
 *      * nebo odeslat jednu zprávu z fronty (když připojeno).
 * - Po úspěšném připojení se navíc pokusí frontu vyprázdnit co nejrychleji.
 *
 * Watchdog sleduje život workeru skrze signál heartbeat("mqtt").
 */
class MqttWorker : public QObject {
    Q_OBJECT
   public:
    explicit MqttWorker(QObject* parent = nullptr);
    ~MqttWorker();

   signals:
    void heartbeat(const QString& name);    // pro watchdog ("mqtt")
    void connectedChanged(bool ok);         // do Backend
    void errorOccured(const QString& msg);  // volitelné, do logů/GUI

   public slots:
    void start();                             // vytvoří klienta, spustí timer a pokusí se připojit
    void stop();                              // zastaví timer a odpojí se
    void publish(const QByteArray& payload);  // požadavek od Backend – jen zařadí do fronty

   private slots:
    void onStateChanged(int s);
    void onErrorChanged();
    void onTimer();  // 20 s perioda – reconnect / odeslání

   private:
    void ensureClient();   // lazy vytvoření MQTT klienta
    void flushQueueNow();  // pokusí se vyprázdnit buffer (pouze pokud jsme připojeni)

    QMqttClient* mqtt_ = nullptr;
    QTimer* timer_ = nullptr;

    // fronta čekajících zpráv
    QQueue<QByteArray> buffer_;

    // konfigurace brokeru
    const QString brokerHost_ = "192.168.3.101";
    const quint16 brokerPort_ = 8883;
    const QString brokerUser_ = "device1";
    const QString brokerPass_ = "pass1";
    const QString topic_ = "devices/device1/telemetry";
    const QString ca_file_ = "/usr/local/share/ca-certificates/rootCA.pem";

    // perioda v ms – posílání / reconnect
    const int intervalMs_ = 20000;
};
