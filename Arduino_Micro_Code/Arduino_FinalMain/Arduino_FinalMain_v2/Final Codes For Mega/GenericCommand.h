// GenericCommand.h

#ifndef _GENERICCOMMAND_h
#define _GENERICCOMMAND_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#else
	#include "WProgram.h"
#endif

#include "Configuration.h"
#include <string.h>
#include "SoftwareSerial.h"

class GenericCommand
{
public:
	GenericCommand();
	void addCommand(const char *, void(*)());
	void addDefaultHandler(void(*function)());
	int getCommandCount();
	CommandCallBack getCommandList(int count);
	void runDefaultHandler();
private:
	char delim[MAXDELIMETER];
	int numCommand;
	CommandCallBack CommandList[MAXXBEECOMMANDS];
	void(*defaultHandler)();
};

#endif

