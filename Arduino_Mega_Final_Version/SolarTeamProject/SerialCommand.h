// SerialCommand.h

#ifndef _SERIALCOMMAND_h
#define _SERIALCOMMAND_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
	
#else
	#include "WProgram.h"
#endif

#define SERIALCOMMANDBUFFER 6
#define MAXSERIALCOMMANDS 20
#define MAXDELIMETER 2

#include <SoftwareSerial.h>
#include <HardwareSerial.h>
#include "Configuration.h"
#include <string.h>

class SerialCommand
{
	public:
		//SerialCommand();
		SerialCommand(SoftwareSerial &SoftSer, HardwareSerial& _HardSer);
		SerialCommand(HardwareSerial &HardSer,bool _isToPcConnection = false);

		void ClearBuffer();
		char *next();
		char *nextString();
		void readSerial();
		void addCommand(const char *, void(*)());
		void addDefaultHandler(void(*function)());
		char Messege[SERIALCOMMANDBUFFER];
private:
		char inChar;
		char buffer[SERIALCOMMANDBUFFER];
		int bufPos;
		char delim[MAXDELIMETER];
		char term;
		char *token;
		char *last;
		typedef struct _callback {
			char command[SERIALCOMMANDBUFFER];
			void(*function)();
		}SerialCommandCallBack;
		void copyBufferToMessege();
		int numCommand;
		SerialCommandCallBack CommandList[MAXSERIALCOMMANDS];
		void(*defaultHandler)();
		int usingSoftwareSerial;
		HardwareSerial &HardSerial;
		SoftwareSerial *SoftSerial;
		bool isToPcConnection;
};

#endif

