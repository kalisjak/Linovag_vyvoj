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

static std::string getId(const char* key, const char* def);
static void setId(const char* key, const QString& id);

QString reclaimOrderNumber();
void setReclaimOrderNumber(const QString& number);

QString reclaimEmail();
void setReclaimEmail(const QString& email);

} // namespace RuntimeConfig
