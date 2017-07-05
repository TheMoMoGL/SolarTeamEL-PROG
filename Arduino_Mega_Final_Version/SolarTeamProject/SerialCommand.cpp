// 
// 
// 
#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

#include "SerialCommand.h"
#include <string.h>
#include "Configuration.h"


SerialCommand::SerialCommand(SoftwareSerial &_SoftSer, HardwareSerial &_HardSer):HardSerial(_HardSer)
{
	usingSoftwareSerial = 1;
	SoftSerial = &_SoftSer;
	strncpy(delim, " ", MAXDELIMETER);
	term = '\r';
	numCommand = 0;
	ClearBuffer();
}
SerialCommand::SerialCommand(HardwareSerial& _HardSer, bool _isToPcConnection = false):HardSerial(_HardSer)
{
	usingSoftwareSerial = 0;
	isToPcConnection = _isToPcConnection;
	//HardSerial.setTimeout(isToPcConnection ? 1000 : 1000);
	strncpy(delim, " ", MAXDELIMETER);
	term = '\r';
	numCommand = 0;
	ClearBuffer();
}

void SerialCommand::ClearBuffer()
{
	for (int i = 0;i < SERIALCOMMANDBUFFER;i++)
	{
		buffer[i] = '\0';
	}

	bufPos = 0;
}

char *SerialCommand::next()
{
	char *nextToken;
	nextToken = strtok_r(NULL, delim, &last);
	return nextToken;
}

char *SerialCommand::nextString()
{
	return Messege;
}

void SerialCommand::readSerial()
{
	while (HardSerial.available()) 
	{
		//THIS COMES FROM XBEE
		inChar = HardSerial.read();
		
		int i;
		boolean matched;

		if (inChar == term)
		{
			bufPos = 0;
			token = strtok_r(buffer, delim, &last);

			if (token == NULL) return;

			matched = false;
			for (i = 0;i < numCommand;i++)
			{
				if (strncmp(token, CommandList[i].command, SERIALCOMMANDBUFFER) == 0)
				{
					(*CommandList[i].function)();
					ClearBuffer();
					matched = true;
					break;
				}
			}
			//TODO: Fix this for getting communication
			if (matched == false)
			{
				(*defaultHandler)();	
				ClearBuffer();
			}
		}
		if (isprint(inChar))
		{
			buffer[bufPos++] = inChar;
			buffer[bufPos] = '\0';
			
			if (bufPos > SERIALCOMMANDBUFFER - 1) bufPos = 0;
		}
	}
}

void SerialCommand::addCommand(const char *command, void(*function)())
{
	if (numCommand < MAXSERIALCOMMANDS) {
		strncpy(CommandList[numCommand].command, command, SERIALCOMMANDBUFFER);
		CommandList[numCommand].function = function;
		numCommand++;
	}
	else {

	}
}

void SerialCommand::addDefaultHandler(void(*function)())
{
	defaultHandler = function;
}

void SerialCommand::copyBufferToMessege()
{
	//mallloc if needed
	//malloc(SERIALCOMMANDBUFFER);
	strcpy(Messege,buffer);
}

