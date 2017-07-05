// 
// 
// 
#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#include "SoftwareSerial.h"
#else
#include "WProgram.h"
#endif

#include "GenericCommand.h"
#include <string.h>
GenericCommand::GenericCommand()
{
	numCommand = 0;
	strncpy(delim, " ", MAXDELIMETER);
}

void GenericCommand::addCommand(const char *command, void(*function)())
{
	if (numCommand < MAXXBEECOMMANDS) {
		strncpy(CommandList[numCommand].command, command, XBEECOMMANDBUFFER);
		CommandList[numCommand].function = function;
		numCommand++;
	}
	else {

	}
}

void GenericCommand::addDefaultHandler(void(*function)())
{
	defaultHandler = function;
}

int GenericCommand::getCommandCount()
{
	return numCommand;
}

CommandCallBack GenericCommand::getCommandList(int count)
{
	return CommandList[count];
}

void GenericCommand::runDefaultHandler()
{
	(*defaultHandler)();
}
