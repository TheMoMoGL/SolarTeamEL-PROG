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
#ifndef SERIALCOMMAND_HARDWAREONLY
#include <SoftwareSerial.h>
#endif // !SERIALCOMMAND_HARDWAREONLY


SerialCommand::SerialCommand()
{
	usingSoftwareSerial = 0;
	strncpy(delim, " ", MAXDELIMETER);
	term = '\r'; //default terminator is return char you can change it!
	numCommand = 0;// no callback yet
	ClearBuffer();
}

#ifndef SERIALCOMMAND_HARDWAREONLY
SerialCommand::SerialCommand(SoftwareSerial &_SoftSer)
{
	usingSoftwareSerial = 1;
	SoftSerial = &_SoftSer;
	strncpy(delim, " ", MAXDELIMETER);
	term = '\r';
	numCommand = 0;
	ClearBuffer();
}
#endif // !SERIALCOMMAND_HARDWAREONLY

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
	//char *nextToken;
	//nextToken = strtok_r(NULL, delim, &last);
	return buffer;
}

void SerialCommand::readSerial()
{
#ifdef SERIALCOMMAND_HARDWAREONLY
	while (Serial.available() > 0)
#else
	while ((usingSoftwareSerial == 0 && Serial.available() > 0) ||
		usingSoftwareSerial == 1 && SoftSerial->available() > 0)
#endif
	{
		int i;
		boolean matched;

		if (usingSoftwareSerial == 0)
		{
			inChar = Serial.read();
		}
		else
		{
#ifndef SERIALCOMMAND_HARDWAREONLY
			inChar = SoftSerial->read();
#endif
		}

#ifdef SERIALCOMMANDDEBUG
		Serial.print(inChar);//echo
#endif
		if (inChar == term)
		{
#ifdef SERIALCOMMANDDEBUG
			Serial.print("Recived: ");
			Serial.println(buffer);
#endif // SERIALCOMMANDDEBUG

			bufPos = 0;
			token = strtok_r(buffer, delim, &last);

			if (token == NULL) return;

			matched = false;
			for (i = 0;i < numCommand;i++)
			{
#ifdef SERIALCOMMANDDEBUG
				Serial.print("Comparing [");
				Serial.print(token);
				Serial.print("] to [");
				Serial.print(CommandList[i].command);
				Serial.println("]");
#endif // SERIALCOMMANDDEBUG

				if (strncmp(token, CommandList[i].command, SERIALCOMMANDBUFFER) == 0)
				{
#ifdef SERIALCOMMANDDEBUG
					Serial.print("Matched Command: ");
					Serial.println(token);
#endif SERIALCOMMANDDEBUG

					(*CommandList[i].function)();
					ClearBuffer();
					matched = true;
					break;
				}
			}
			//TODO: Fix this for getting communication
			if (matched == false)
			{
				//copyBufferToMessege();
				(*defaultHandler)();

				
				ClearBuffer();
			}
		}
		if (isprint(inChar))
		{
			//copyBufferToMessege();
			buffer[bufPos++] = inChar;
			buffer[bufPos] = '\0';
			if (bufPos > SERIALCOMMANDBUFFER - 1) bufPos = 0;
		}
	}
}

void SerialCommand::addCommand(const char *command, void(*function)())
{
	if (numCommand < MAXSERIALCOMMANDS) {
#ifdef SERIALCOMMANDDEBUG
		Serial.print(numCommand);
		Serial.print("-");
		Serial.print("Adding command for ");
		Serial.println(command);
#endif

		strncpy(CommandList[numCommand].command, command, SERIALCOMMANDBUFFER);
		CommandList[numCommand].function = function;
		numCommand++;
	}
	else {

#ifdef SERIALCOMMANDDEBUG
		Serial.println("Too many handlers - recompile changing MAXSERIALCOMMANDS");
#endif 
	}
}

void SerialCommand::addDefaultHandler(void(*function)())
{
	defaultHandler = function;
}

void SerialCommand::copyBufferToMessege()
{
	//fgets(buffer, SERIALCOMMANDBUFFER, stdin);
	malloc(SERIALCOMMANDBUFFER);
	strcpy(Messege,buffer);
}
