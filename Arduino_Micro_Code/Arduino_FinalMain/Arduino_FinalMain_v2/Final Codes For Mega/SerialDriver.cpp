// 
// 
// 

#include "SerialDriver.h"

SerialDriver::SerialDriver(unsigned long buadRate, unsigned int RX, unsigned int TX, unsigned long timeOut = 1000, bool setupXbee = false)
{
	term = '\r';
	Serial.setTimeout(timeOut);
	bRate = buadRate;
	startXbee = setupXbee;
	ClearBuffer();
	pos = 0;
	Serial.begin(buadRate);
	Serial.println("Serial communication Started.");
}

void SerialDriver::ClearBuffer()
{
	for (int i = 0;i < MAX_BUFFER_SIZE;i++)
	{
		buffer[i] = '\0';
	}

	bufPos = 0;
}

byte SerialDriver::ReadByte()
{
	if (Serial.available())
	{
		return Serial.read();
	}
}

int SerialDriver::ReadString(char *buffer, const int bufferSize = MAX_BUFFER_SIZE)
{
	//int pos;
	//int rpos;
	while (Serial.available() > 0)
	{
		char inChar = Serial.read();
		if (inChar > 0) {
			switch (inChar) {
			case '\n': // Ignore new-lines
				break;
			case '\r': // Return on CR
				rpos = pos;
				pos = 0;  // Reset position index ready for next time
				return rpos;
			default:
				if (pos < bufferSize - 1) {
					buffer[pos++] = inChar;
					buffer[pos] = 0;
				}
			}
		}
		// No end of line has been found, so return -1.
		return -1;
	}
	//return -1;
}

void SerialDriver::WriteString(char * buffer)
{
}


void SerialDriver::StartXbee()
{
	if (!startXbee) return;

	//xBee.begin(bRate);
}