#pragma once

#include <QString>
#include <string>

namespace RuntimeConfig {

// Device serial (SN-xxxx)
QString deviceSerial();
void setDeviceSerial(const QString& serial);

// DS18B20 senzory 1 a 2
std::string sensor1Id();
void setSensor1Id(const QString& id);

std::string sensor2Id();
void setSensor2Id(const QString& id);

std::string sensor3Id();
void setSensor3Id(const QString& id);

QString reclaimOrderNumber();
void setReclaimOrderNumber(const QString& number);

QString reclaimEmail();
void setReclaimEmail(const QString& email);

} // namespace RuntimeConfig
