#pragma once

#include <QString>
#include <string>

namespace RuntimeConfig {

// Device serial (SN-xxxx)
QString deviceSerial();
void setDeviceSerial(const QString& serial);

// Software type: 3 nebo 22
int softwareType();
void setSoftwareType(int type);

// DS18B20 IDs
// Well
std::string sensor1Id();
void setSensor1Id(const QString& id);

// Well (typ-2+2)
std::string sensor2Id();
void setSensor2Id(const QString& id);

// Evap1
std::string sensor3Id();
void setSensor3Id(const QString& id);

// Evap2 (typ 2+2)
std::string sensor4Id();
void setSensor4Id(const QString& id);

// condensator
std::string sensor5Id();
void setSensor5Id(const QString& id);

// DHT22 sensor ID (může být DS18B20 pro simulaci)
std::string sensor6Id();
void setSensor6Id(const QString& id);

// Sensor offsets (°C)
double sensor1Offset();
void setSensor1Offset(double off);

double sensor2Offset();
void setSensor2Offset(double off);

double sensor3Offset();
void setSensor3Offset(double off);

double sensor4Offset();
void setSensor4Offset(double off);

double sensor5Offset();
void setSensor5Offset(double off);

double sensor6Offset();
void setSensor6Offset(double off);

// ===== Auto defrost schedule =====
// enabled = whether scheduled defrost is active
bool autoDefrostEnabled();
void setAutoDefrostEnabled(bool en);

// Times are minutes since midnight (0..1439)
int autoDefrostTime1Min();
void setAutoDefrostTime1Min(int minutes);

int autoDefrostTime2Min();
void setAutoDefrostTime2Min(int minutes);

static std::string getId(const char* key, const char* def);
static void setId(const char* key, const QString& id);

QString reclaimOrderNumber();
void setReclaimOrderNumber(const QString& number);

QString reclaimEmail();
void setReclaimEmail(const QString& email);

// App language (e.g. "cs", "en", "de", "pl")
QString appLanguage();
void setAppLanguage(const QString& lang);

} // namespace RuntimeConfig
