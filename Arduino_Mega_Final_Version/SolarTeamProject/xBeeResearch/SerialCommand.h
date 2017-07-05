// SerialCommand.h

#ifndef _SERIALCOMMAND_h
#define _SERIALCOMMAND_h

#if defined(ARDUINO) && ARDUINO >= 100
#include "arduino.h"
#else
#include "WProgram.h"
#endif

#include "Configuration.h"
#include <string.h>
#include "SoftwareSerial.h"

class SerialCommand
{
public:
	SerialCommand();
// #ifndef SERIALCOMMAND_HARDWAREONLY
//	void SerialCommand(SoftwareSerial &_SoftSer);
	void ClearBuffer();
	char* next();
	char* nextString();
	void readSerial();
	void addCommand(const char *command, void(*function)());
	void addDefaultHandler(void(*function)());
	void copyBufferToMessege();

	void addDefaultHandler(void(*function)());
	int getCommandCount();
	CommandCallBack getCommandList(int count);
	void runDefaultHandler();
private:
	char delim[MAXDELIMETER];
	int numCommand;
	int usingSoftwareSerial;
	char term;
	CommandCallBack CommandList[MAXXBEECOMMANDS];
	void(*defaultHandler)();
};

#endif