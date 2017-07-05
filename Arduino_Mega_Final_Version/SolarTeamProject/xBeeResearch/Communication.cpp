// 
// 
// 

#include "Communication.h"

SoftwareSerial xBee(XBEE_RX_PIN,XBEE_TX_PIN);

bool SetupSerial(unsigned long buadRate)
{
	//TODO: Just a check, most probably need to be removed since HW not avb yet.
	if (Serial.available() == false)
		return false;

	Serial.begin(buadRate);
	return true;
}
void SetupXbee(unsigned long buadRate)
{
	xBee.begin(buadRate);
}

byte SerialReadByte()
{
	if (xBee.available()) {
		byte temp = xBee.read();
		return temp;
	}

	return NULL;
}

int SerialReadString(char* buffer, int bufferSize)
{
	for (int index = 0; index < bufferSize;index++)
	{
		while (Serial.available() == 0) {}

		char ch = Serial.read();
		Serial.print(ch);//TODO : this is for echoing (test) will be removed!

		if (ch == '\n')
		{
			buffer[index] = 0;//end of line
			return index;
		}
		buffer[index] = ch;
	}

	// this will prevent if there is a long wait between chars so we start again and discard half baked values
	char ch;
	do 
	{
		while (Serial.available() == 0){}
		ch = Serial.read();
		Serial.print(ch);//just echo
	} while (ch != '\n');

	buffer[0] = 0;
	return -1;
}

int SerialWriteString(char * buffer, int bufferSize)
{
	return 0;
}
