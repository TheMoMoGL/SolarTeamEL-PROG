// Communication.h
// All the code for Serial/xBee comunication shall be placed here

#ifndef _COMMUNICATION_h
#define _COMMUNICATION_h

#include <SoftwareSerial.h>
#include "Configuration.h"

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#else
	#include "WProgram.h"
#endif

bool SetupSerial(unsigned long buadRate);
void SetupXbee(unsigned long buadRate);
byte SerialReadByte();
int SerialReadString(char* buffer, int bufferSize);
int SerialWriteString(char* buffer, int bufferSize);

byte XbeeReadByte(char c);
int XbeeReadString(char* buffer, int bufferSize);
int xBeeWriteString(char* buffer, int bufferSize);

#endif

