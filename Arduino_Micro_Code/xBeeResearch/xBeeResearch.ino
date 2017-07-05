byte shit_var = 0; //this shit is tricky 
//THIS VAR IS USED TO TRICK COMPILER AND DONT MESS WITH
//GENERATED CODES, SO FIRST FEW LINES WILL BE ALRIGHT
//QUITE MAGICAL RIGHT (; WELL ARDUINO COMPILER SUCKS

//We are research

#pragma region Includes
#include "GenericCommand.h"
#include <HardwareSerial.h>
#include <SoftwareSerial.h>
#include "SerialCommand.h"
#include "Configuration.h"
#include <string.h>
#include <mcp2515_defs.h>
#include <mcp2515.h>
#include <global.h>
#include <defaults.h>
#include <Canbus.h>
#include <LiquidCrystal.h>
#pragma endregion

#pragma region Declarations

#pragma region Communication Vars
//FOR MEGA BOARD SOFTWARE SERIAL USE RX = 11 TX = 12
//FOR UNO BOARD SOFTWARE SERIAL USE RX = 7 TX = 8

bool CAN_INITIALIZED = false;
char *EngineRPM;
unsigned char eBuffer[CAN_MESSEGE_BUFFER_SIZE];
unsigned char *eBuPointer;
char dataToSend[CAN_MESSEGE_BUFFER_SIZE + 3];//total 12 char plus \0 termination


#define USE_SOFTWARE_SERIAL 0
#define DEBUG_ENABLED 1
HardwareSerial *HardSerial_xBeeToxBee = &Serial;
bool stopShit;
#if USE_SOFTWARE_SERIAL == 1
//DONT FORGET TO CHANGE TO UNO SDK IF UNO BOARD IS USED
//SoftwareSerial SoftSerial_ArduinoToPC = SoftwareSerial(ARDUINO_MEGA_SOFT_SERIAL_RX, ARDUINO_MEGA_SOFT_SERIAL_TX); MEGA
SoftwareSerial *SoftSerial_ArduinoToPC = &SoftwareSerial(ARDUINO_UNO_SOFT_SERIAL_RX, ARDUINO_UNO_SOFT_SERIAL_TX);//UNO
SerialCommand Commands_Soft_Hard_Serial(*SoftSerial_ArduinoToPC, *HardSerial_xBeeToxBee);
GenericCommand Commands_xBee;
#else
//This is if Mega board is used,
//Change the board SDK to mega in the IDE then use the hardware serial port you like
//Mega boad avaible serials: Serial1, Serial2 or Serial3
HardwareSerial *HardSerial_ArduinoToPC = &Serial3;
//SerialCommand Commands_SerialToPC(HardSerial_ArduinoToPC, true);
SerialCommand Commands_xBeeToxBee(*HardSerial_xBeeToxBee);

#endif 
#pragma endregion

#pragma region LCD & PID
/*
Pin setup

Vss - Gnd
Vdd - 5V
V0  - Contrast, potentiometer or 2.7kohm then Gnd
Rs  - pin 36
R/W - Gnd
E   - pin 34
D4  - pin 32
D5  - pin 30
D6  - pin 28
D7  - pin 26
A   - 5V (220ohm then 5V)
K   - Gnd

*/

#define Radius 0.16f
#define Magnets 1.5f
#define StartWatch 0
#define StopWatch 1
#define Standby 2
#define Update 500

int ReadThrottlePin = 15;       // Analog pin 1   | Analog pin 15       - Th_in
int interruptPin = 3;           // Digital pin 2  | Digital pin 3       - Hall
int CruisePin = 24;             // Digital pin 3  | Digital pin 24      - Cruise
int ThrottlePin = 46;           // Digital pin 4  | Digital pin 46      - Th_out
int BrakePin = 4;

unsigned long T0, T1, T2, D, Delay1 = 0, Delay2 = 0;
char State = 0;
unsigned long Factor = 3.6f * PI * Radius * 1000000.0f / Magnets;

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(36, 34, 32, 30, 28, 26);

String Line11 = "Speed  : ";
String Line12 = " km/h  ";

String Line21 = "BatWarn: ";
String BatteryWarnings = "NONE";

String Line31 = "BatPwr : ";
String Line32 = " Volt  ";

String Line41 = "CruiseC: ";
String Line42 = "OFF";

uint8_t velocity[] = { 0,0,0 };
uint8_t   Increment = 0;
volatile uint8_t   Speed = 0;
volatile int       Throttle = 0;
volatile uint8_t   CruiseSpeed = 0;
uint8_t   Cruise = 0;
int       BatPwr = 0;
boolean   Deactivated = true;
bool IS_CRUSE_CONTROL_ENABLED = false;

//*******PID**********//
int Last = 0;
int Error = 0;
int Integral = 0;
int IntThresh = 1000;
int ScaleFactor = 0.1;

//uint8_t   kP = 10;
//uint8_t   kD = 11;
//uint8_t   kI = 1;
volatile uint8_t   kP = 0;
volatile uint8_t   kD = 0;
volatile uint8_t   kI = 0;
#pragma endregion

#pragma endregion

#pragma region Arduino Setup/Loop
void setup()
{
	delay(1000);//WAIT 1 SECONDS TO SETUP SERIAL MONITOR ON PC JUST FOR TESTING
	setupSerialPorts();
	setupxBeeCommandsHard();

	//Setup debug LED
	pinMode(ARDUINO_DEBUG_LED, OUTPUT);
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	//flushPCCommuincation();
	delay(100);
	stopShit = false;
	setupCANBus();
	setupPIDandLCD();
	//Speed = 0;
	//CruiseSpeed = 0;
	//Cruise = 1;
	//Deactivated = true;
}

void loop()
{
#if USE_SOFTWARE_SERIAL == 1
	//read from PC on Software Serial
	Commands_Soft_Hard_Serial.readSerial();
	//read from xBee on Hardware Serial
	ReadFromXBee();
#else
	//Communication Code
	Commands_xBeeToxBee.readSerial();
	delay(10);
	scanCANbus();
	delay(10);

	//PID Code
	if (Delay1 == 0) {
		Delay1 = millis();
	}

	CruiseControl();
	upateSpeed();
	Delay2 = millis();
	if (Delay2 - Delay1 > Update) {
		Increment++;
		DisplayState(Increment);
		Delay1 = 0;
		Delay2 = 0;
	}
#endif
}
#pragma endregion


#pragma region	CAN Bus Reader


void scanCANbus()
{
	if (!CAN_INITIALIZED) return;

	tCAN message;
	//For debugging only
	//HardSerial_xBeeToxBee.println("SCANING: ");
	//It only sends to hardware serial, if you want to use with Uno or software serial just 
	//Change the Hardserial to Soft serial
	if (mcp2515_check_message())
	{
		if (mcp2515_get_message(&message))
		{

			//if(message.id == 0x620 and message.data[2] == 0xFF)  //uncomment when you want to filter
			//{




			HardSerial_xBeeToxBee->print("ID: ");
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->print("ID: ");
#endif

			HardSerial_xBeeToxBee->print(message.id, HEX);
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->print(message.id, HEX);
#endif

			HardSerial_xBeeToxBee->print(", ");
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->print(", ");
#endif

			HardSerial_xBeeToxBee->print("Data: ");
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->print("Data: ");
#endif


			HardSerial_xBeeToxBee->print(message.header.length, DEC);
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->print(message.header.length, DEC);
#endif


			HardSerial_xBeeToxBee->print(", ");
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->print(", ");
#endif


			for (int i = 0;i < message.header.length;i++)
			{
				//HardSerial_ArduinoToPC.print(message.data[i], HEX);
				HardSerial_xBeeToxBee->print(char(message.data[i]));
#if (DEBUG_ENABLED == 1)
				HardSerial_ArduinoToPC->print(char(message.data[i]));
#endif

				HardSerial_ArduinoToPC->print(char(message.data[i]));
			}
			HardSerial_xBeeToxBee->println("");
#if (DEBUG_ENABLED == 1)
			HardSerial_ArduinoToPC->println("");
#endif

			//}
		}
	}
}


//TODO: remove later if we dont need it
//void readCANbus()
//{
//	//TODO later add messege ID to PC as well
//	//Canbus.ecu_req(TEST_MSG_ID, eBuffer);
//
//	Canbus.message_rx(eBuPointer);
//	delay(100);
//
//	int sizeOfBuffer = sizeof(eBuPointer);
//
//
//	//exit if there is no number
//	//TODO add extra check for spceial math char such as dot (.) and (- +) signs
//	/*if (!isdigit(eBuffer[0]))
//		return;
//	*/
//	//sprintf(dataToSend, "%s=%s", GET_ENGINE_RPM_PREFIX, eBuffer);
//	//HardSerial_xBeeToxBee.println(dataToSend);
//	for (int i = 0;i <= sizeOfBuffer - 1;i++)
//	{
//		sprintf(dataToSend, "%s[%d]=%s", "Buf", i, eBuPointer[i]);
//		HardSerial_ArduinoToPC.println(dataToSend);
//	}
//
//	//HardSerial_ArduinoToPC.println(eBuffer[0]);
//	//HardSerial_xBeeToxBee.println(eBuffer[0]);
//
//	//this delay is because CAN speed is much faster than current uart setting
//	//extra calcualtion and testing is needed to sync speed between CAN and uart
//	//transmit so we dont lose any data
//	delay(100);
//
//}

#pragma endregion

#pragma region Read from xBee Software mode enabled
char inChar;
char buffer[XBEECOMMANDBUFFER];
int bufPos = 0;
char delim[MAXDELIMETER];
char *token;
char *last;
void ClearBuffer()
{
	for (int i = 0;i < XBEECOMMANDBUFFER;i++)
	{
		buffer[i] = '\0';
	}

	bufPos = 0;
}
void ReadFromXBee()
{
#if USE_SOFTWARE_SERIAL == 1
	//Add code to process data coming from xbee on hardware serial 0
	while (HardSerial_xBeeToxBee.available() > 0)
	{
		inChar = HardSerial_xBeeToxBee.read();

		int i;
		boolean matched;

		if (inChar == '\n')
		{
			bufPos = 0;
			token = strtok_r(buffer, delim, &last);
			if (token == NULL) return;

			for (i = 0;i < Commands_xBee.getCommandCount();i++)
			{
				if (strncmp(token, Commands_xBee.getCommandList(i).command, XBEECOMMANDBUFFER) == 0)
				{
					(*Commands_xBee.getCommandList(i).function)();
					ClearBuffer();
					matched = true;
					break;
				}
			}


			if (matched == false)
			{
				Commands_xBee.runDefaultHandler();
				ClearBuffer();
			}
		}
		if (isprint(inChar))
		{
			buffer[bufPos++] = inChar;
			buffer[bufPos] = '\0';

			if (bufPos > XBEECOMMANDBUFFER - 1) bufPos = 0;
		}
	}
#endif
}
#pragma endregion

#pragma region Setup Communication & LCD

void setupSerialPorts()
{
#if USE_SOFTWARE_SERIAL == 1
	SoftSerial_ArduinoToPC->begin(BUAD_RATE);
	HardSerial_xBeeToxBee->begin(BUAD_RATE);
	SoftSerial_ArduinoToPC->println("S.Serial initialized");
#else
	HardSerial_xBeeToxBee->begin(BUAD_RATE);
	HardSerial_ArduinoToPC->begin(115200);

	HardSerial_xBeeToxBee->println("Xbee Port initialized");
	HardSerial_ArduinoToPC->println("H.Serial initialized");
#endif
}

void setupCANBus()
{
	HardSerial_xBeeToxBee->println("Setting up CAN");
	HardSerial_ArduinoToPC->println("Setting up CAN");
	delay(1000);
	/* Initialize MCP2515 CAN controller at the specified speed */
	
	if (Canbus.init(CANSPEED_500))
	{
		HardSerial_xBeeToxBee->println("CAN Init Ok");
		HardSerial_ArduinoToPC->println("CAN Init Ok");
		CAN_INITIALIZED = true;
		
	}
	else
	{
		HardSerial_xBeeToxBee->println("Can't init CAN");
		HardSerial_ArduinoToPC->println("Can't init CAN");
		CAN_INITIALIZED = false;
	
	}
	delay(10);
}


void setupxBeeCommandsHard()
{
#if USE_SOFTWARE_SERIAL == 1
#else

	Commands_xBeeToxBee.addCommand("ON", LED_on);//Testing
	Commands_xBeeToxBee.addCommand("OFF", LED_off);//Testing
	Commands_xBeeToxBee.addCommand("START", start_Shit);//Testing
	Commands_xBeeToxBee.addCommand("STOP", stop_Shit);//Testing
	Commands_xBeeToxBee.addCommand("GETSP", get_Speed);
	Commands_xBeeToxBee.addCommand("GETTT", getThrottle);
	Commands_xBeeToxBee.addCommand("TT", updateThrottle);
	Commands_xBeeToxBee.addCommand("CC", updateCruseSpeed);
	Commands_xBeeToxBee.addCommand("ECC", enableCruseControl);//Enable cruse control
	Commands_xBeeToxBee.addCommand("DCC", disableCruseControl);//Disable cruse control
	Commands_xBeeToxBee.addCommand("GETCC", getCruseControlStatus);//get cruse control status
	Commands_xBeeToxBee.addCommand("CCSP", getCruseControlSpeed);//get cruse control status
	Commands_xBeeToxBee.addCommand("P", updatePID_P);//
	Commands_xBeeToxBee.addCommand("I", updatePID_I);//
	Commands_xBeeToxBee.addCommand("D", updatePID_D);//
	Commands_xBeeToxBee.addCommand("PID", getPID);//get PID values

	Commands_xBeeToxBee.addDefaultHandler(unrecognizedCommand);
	HardSerial_xBeeToxBee->println("H. xBee Commands Added");
	HardSerial_ArduinoToPC->println("H. xBee Commands Added");

#endif
}

void setupSoftSerialCommands()
{
#if USE_SOFTWARE_SERIAL == 1
	Commands_Soft_Hard_Serial.addCommand("ON", LED_on);
	Commands_Soft_Hard_Serial.addCommand("OFF", LED_off);
	Commands_Soft_Hard_Serial.addCommand("START", start_Shit);
	Commands_Soft_Hard_Serial.addCommand("STOP", stop_Shit);
	Commands_Soft_Hard_Serial.addCommand("HS", HandShake);
	Commands_Soft_Hard_Serial.addDefaultHandler(unrecognizedCommand);

	SoftSerial_ArduinoToPC->println("Commands added");
#endif
}

void setupxBeeCommands()
{
#if USE_SOFTWARE_SERIAL == 1
	Commands_xBee.addCommand("LEDON", LED_on_FromxBee);
	Commands_xBee.addCommand("LEDOFF", LED_off_FromxBee);
	Commands_xBee.addDefaultHandler(unrecognizedFromxBee);

	SoftSerial_ArduinoToPC->println("xBee. Commands added");
#endif
}

void setupPIDandLCD() 
{
	//Setup PID & control pins 
	pinMode(interruptPin, INPUT);
	pinMode(CruisePin, INPUT);
	pinMode(BrakePin, INPUT);
	pinMode(ThrottlePin, OUTPUT);
	pinMode(ReadThrottlePin, INPUT);
	attachInterrupt(digitalPinToInterrupt(interruptPin), Change, RISING);
	HardSerial_xBeeToxBee->println("PID initialized.");

	//Setup LCD
	lcd.begin(20, 4);     // set up the LCD's number of columns and rows:
	lcd.print("Start");   // Print a message to the LCD.
	DisplayState(Increment);
	HardSerial_xBeeToxBee->println("LCD initialized.");
}

#pragma endregion

#pragma region Callback Functions
void LED_on()
{
#if USE_SOFTWARE_SERIAL == 1
	delay(100);
	digitalWrite(ARDUINO_DEBUG_LED, HIGH);
	SoftSerial_ArduinoToPC->println("LED is ON");

#else
	//delay(100);
	digitalWrite(ARDUINO_DEBUG_LED, HIGH);
	HardSerial_xBeeToxBee->println("LED is ON");

#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println("LED is ON");
#endif




#endif
}

void LED_off()
{
#if USE_SOFTWARE_SERIAL == 1
	//delay(100);
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	//delay(100);
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	HardSerial_xBeeToxBee->println("LED is OFF");
#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println("LED is OFF");
#endif

#endif
}

void HandShake()
{
#if USE_SOFTWARE_SERIAL == 1
	delay(100);
	SoftSerial_ArduinoToPC->println("HS");
#else
	//delay(100);
	HardSerial_xBeeToxBee->println("HS");
#endif
#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println("HS");
#endif
}


void get_Speed()
{
#if USE_SOFTWARE_SERIAL == 1
	delay(100);
	SoftSerial_ArduinoToPC->println("HS");
#else
	//delay(100);
	char* strSpeed;
	strSpeed = int2str(Speed);
	String msg = MSG_HEADER_SPEED;
	msg += strSpeed;
	msg += MSG_FOOTER_SPEED;
	HardSerial_xBeeToxBee->println(msg);
#endif
#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println(Speed);
#endif
}

void start_Shit()
{
#if USE_SOFTWARE_SERIAL == 1
	stopShit = false;
	SoftSerial_ArduinoToPC->println("Shit Started.");
	delay(100);
	int i = 1;

	while (!stopShit)
	{
		SoftSerial_ArduinoToPC->println(i);
		i++;
		//delay(100);
		//read from PC on Software Serial
		Commands_Soft_Hard_Serial.readSerial();
		delay(5);
	}
#else
	stopShit = false;
	HardSerial_xBeeToxBee->println("Shit Started.");
#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println("Shit Started.");
#endif
	delay(100);
	int i = 1;

	while (!stopShit)
	{
		digitalWrite(ARDUINO_DEBUG_LED, HIGH);
#if (DEBUG_ENABLED == 1)
		HardSerial_ArduinoToPC->println(i);
#endif
		HardSerial_xBeeToxBee->println(i);
		i++;
		delay(100);
		digitalWrite(ARDUINO_DEBUG_LED, LOW);
		Commands_xBeeToxBee.readSerial();
		delay(100);
	}

	digitalWrite(ARDUINO_DEBUG_LED, LOW);

#endif
}

void stop_Shit()
{
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	stopShit = true;
#if USE_SOFTWARE_SERIAL == 1
	SoftSerial_ArduinoToPC->println("Shit Stopped.");
#else
	HardSerial_xBeeToxBee->println("Shit Stopped.");
#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println("Shit Stopped.");
#endif
#endif
}

void LED_on_FromxBee()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, HIGH);
	SoftSerial_ArduinoToPC->println("LED is ON");
#else
	digitalWrite(ARDUINO_DEBUG_LED, HIGH);
	HardSerial_ArduinoToPC->println("LED is ON");
#endif
}

void LED_off_FromxBee()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	HardSerial_ArduinoToPC->println("LED is OFF");
#endif
}



void updateCruseSpeed()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);    // Converts a char string to an integer
		CruiseSpeed = aNumber;
		HardSerial_xBeeToxBee->println(CruiseSpeed);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
#endif
}

void updateThrottle()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);    // Converts a char string to an integer
		Throttle = aNumber;
		HardSerial_xBeeToxBee->println(Throttle);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
#endif
}

void getThrottle()
{
	char* t = int2str(Throttle);
	String msg = MSG_HEADER_THROTTLE;
	msg += t;
	msg += MSG_FOOTER_THROTTLE;
	HardSerial_xBeeToxBee->println(msg);
}


void updatePID_P()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);    // Converts a char string to an integer
		kP = aNumber;
		HardSerial_xBeeToxBee->println(kP);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
#endif
}

void updatePID_I()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);    // Converts a char string to an integer
		kI = aNumber;
		HardSerial_xBeeToxBee->println(kI);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
#endif
}

void updatePID_D()
{
#if USE_SOFTWARE_SERIAL == 1
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	SoftSerial_ArduinoToPC->println("LED is OFF");
#else
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);    // Converts a char string to an integer
		kD = aNumber;
		HardSerial_xBeeToxBee->println(kD);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
#endif
}

void getPID()
{
	char* p = int2str(kP);
	String msg = MSG_HEADER_PID;
	msg += p;
	msg += MSG_SEPERATOR;
	char* i = int2str(kI);
	msg += i;
	msg += MSG_SEPERATOR;
	char* d = int2str(kD);
	msg += d;
	msg += MSG_FOOTER_PID;
	HardSerial_xBeeToxBee->println(msg);
}



// This gets set as the default handler, and get called for communications only. 
// Make sure the sending messege is not like command list.
void unrecognizedCommand()
{
#if USE_SOFTWARE_SERIAL == 1
	SoftSerial_ArduinoToPC->println("Unrecognized command");
#else
	HardSerial_xBeeToxBee->println("Unrecognized command");
#if (DEBUG_ENABLED == 1)
	HardSerial_ArduinoToPC->println("Unrecognized command");
#endif

#endif
}
//we can use this defualt handler to read data form xBee as well
void unrecognizedFromxBee()
{
#if USE_SOFTWARE_SERIAL == 1
	SoftSerial_ArduinoToPC->println("Bad incomming");
#else
	HardSerial_xBeeToxBee->println("Bad incomming");
#endif
}

void flushPCCommuincation()
{
#if USE_SOFTWARE_SERIAL == 1
	while (SoftSerial_ArduinoToPC->available() > 0) SoftSerial_ArduinoToPC->read();
#else
	while (HardSerial_ArduinoToPC->available() > 0) HardSerial_ArduinoToPC->read();
#endif
}

char _int2str[7];
char* int2str(register int i) {
	register unsigned char L = 1;
	register char c;
	register boolean m = false;
	register char b;  // lower-byte of i
					  // negative
	if (i < 0) {
		_int2str[0] = '-';
		i = -i;
	}
	else L = 0;
	// ten-thousands
	if (i > 9999) {
		c = i < 20000 ? 1
			: i < 30000 ? 2
			: 3;
		_int2str[L++] = c + 48;
		i -= c * 10000;
		m = true;
	}
	// thousands
	if (i > 999) {
		c = i < 5000
			? (i < 3000
				? (i < 2000 ? 1 : 2)
				: i < 4000 ? 3 : 4
				)
			: i < 8000
			? (i < 6000
				? 5
				: i < 7000 ? 6 : 7
				)
			: i < 9000 ? 8 : 9;
		_int2str[L++] = c + 48;
		i -= c * 1000;
		m = true;
	}
	else if (m) _int2str[L++] = '0';
	// hundreds
	if (i > 99) {
		c = i < 500
			? (i < 300
				? (i < 200 ? 1 : 2)
				: i < 400 ? 3 : 4
				)
			: i < 800
			? (i < 600
				? 5
				: i < 700 ? 6 : 7
				)
			: i < 900 ? 8 : 9;
		_int2str[L++] = c + 48;
		i -= c * 100;
		m = true;
	}
	else if (m) _int2str[L++] = '0';
	// decades (check on lower byte to optimize code)
	b = char(i);
	if (b > 9) {
		c = b < 50
			? (b < 30
				? (b < 20 ? 1 : 2)
				: b < 40 ? 3 : 4
				)
			: b < 80
			? (i < 60
				? 5
				: i < 70 ? 6 : 7
				)
			: i < 90 ? 8 : 9;
		_int2str[L++] = c + 48;
		b -= c * 10;
		m = true;
	}
	else if (m) _int2str[L++] = '0';
	// last digit
	_int2str[L++] = b + 48;
	// null terminator
	_int2str[L] = 0;
	return _int2str;
}


#pragma endregion

#pragma region LCD & PID Codes
int PID_controller() {

	Error = CruiseSpeed - Speed;

	if (abs(Error) < IntThresh) {                     // prevent integral 'windup'
		Integral = Integral + Error;                    // accumulate the error integral
	}
	else {
		Integral = 0;                                     // zero it if out of bounds
	}
	float P = Error*(float)kP*0.1;                                // calc proportional term
	float I = Integral*(float)kI*0.1;                             // integral term
	float D = (Last - Speed)*(float)kD*0.1;                         // derivative term
	Throttle = P + I + D + Throttle;                            // Total drive = P+I+D
	//Throttle = Throttle*ScaleFactor;                 // scale Drive to be in the range 0-255
	if (Throttle>255) {
		Throttle = 255;
	}
	else if (Throttle<0) {
		Throttle = 0;
	}
	Last = Speed;                                    // save current value for next time 

	return Throttle;
}

void DisplayState(int Increment) {

	if (0 == Increment % 10) {

		Clear();

		Increment = 0;

		lcd.setCursor(0, 0);
		lcd.print(Line11 + Speed + Line12);

		lcd.setCursor(0, 1);
		lcd.print(Line21 + BatteryWarnings);

		lcd.setCursor(0, 2);
		lcd.print(Line31 + BatPwr + Line32);

		lcd.setCursor(0, 3);
		lcd.print(Line41 + Line42);

	}
	else {

		lcd.setCursor(9, 0);
		lcd.print(Speed + Line12);

		lcd.setCursor(9, 1);
		lcd.print(BatteryWarnings);

		/*lcd.setCursor(9, 2);
		lcd.print(BatPwr + Line32);*/

		lcd.setCursor(9, 2);
		lcd.print(Error + Line32);

		

		lcd.setCursor(9, 3);
		lcd.print(Line42);

	}
}

void Clear() {

	for (int i = 0; i<4; i++) {

		for (int j = 0; j<20; j++) {

			lcd.setCursor(j, i);
			lcd.print(" ");
		}
	}
}

void BatteryCheck() {

	//BatPwr = analogRead(BatPin) * (5.0 / 1023.0) * 9;
}

void CruiseControl() {

	if (Cruise == 1 && Deactivated) {
		Line42 = "ON ";
		analogWrite(ThrottlePin, PID_controller());
		//analogWrite(ThrottlePin, Throttle);
	}
	else {
		Line42 = "OFF";
		Throttle = analogRead(ReadThrottlePin);
		Throttle = map(Throttle, 0, 1023, 0, 290);
		//Throttle = map(Throttle, 0, 100, 0, 255);
		analogWrite(ThrottlePin, Throttle);
	}

	//TODO Uncomment this after testing
	//Comment for testing throttle
	if (digitalRead(CruisePin) == HIGH) {
		Cruise = 1;
	}
	else {
		Cruise = 0;
		Deactivated = true;
	}

	if (digitalRead(BrakePin) == HIGH) {
		Deactivated = false;
	}
}


void upateSpeed() {

	/*switch (State) {
	case StartWatch:
		T1 = micros();
		State = Standby;
		break;
	case StopWatch:
		T2 = micros();
		D = T2 - T1;
		Speed = Factor / D;
		State = StartWatch;
		break;
	}
	if (micros() - T1>1000000) {
		Speed = 0;
	}*/

	//TODO: fix it
	//Speed = (velocity[0] + velocity[1] + velocity[2]) / 3;
	//Speed = (velocity[0] + velocity[1] + velocity[2]) / 3;

	if (micros() - T1>1000000) {
		/*velocity[0] = 0;
		velocity[1] = 0;
		velocity[2] = 0;*/
		Speed = 0;
	}
}

volatile byte velocityCounter = 0;
void Change() {

	if (State == Standby) {
		State = StopWatch;
	}

	//TODO: make it cleaner and better
	velocityCounter += 1;
	if (velocityCounter > 2)
	{
		velocityCounter = 0;
	}

	switch (State) {
	case StartWatch:
		T1 = micros();
		State = Standby;
		break;
	case StopWatch:
		T2 = micros();
		D = T2 - T1;
		//velocity[velocityCounter] = Factor / D;
		Speed = Factor / D;
		State = StartWatch;
		break;
	}
}

void enableCruseControl()
{
	Cruise = 1;
	Deactivated = false;
	HardSerial_xBeeToxBee->println("CC Enabled");
}

void disableCruseControl()
{
	Cruise = 0;
	Deactivated = true;
	HardSerial_xBeeToxBee->println("CC Disabled");
}

void getCruseControlStatus()
{
	char ccStatus = Cruise == 1 ? '1' : '0';
	String msg = MSG_HEADER_CC_STATUS;
	msg += ccStatus;
	msg += MSG_FOOTER_CC_STATUS;
	HardSerial_xBeeToxBee->println(msg);
}

void getCruseControlSpeed()
{
	char* ccSpeed = int2str(CruiseSpeed);
	String msg = MSG_HEADER_CC_SPEED;
	msg += ccSpeed;
	msg += MSG_FOOTER_CC_SPEED;
	HardSerial_xBeeToxBee->println(msg);
}


void DisableI2CInterface()
{
	//https://forum.arduino.cc/index.php?topic=350128.0
	//http://www.varesano.net/blog/fabio/how-disable-internal-arduino-atmega-pullups-sda-and-scl-i2c-bus
	TWCR = _BV(TWEN) | _BV(TWSTO); // no interrupts, Set Stop(release buss)
	TWCR = _BV(TWSTO); // no interrupts, Set Stop(release buss), disable TWI interface

	pinMode(interruptPin, INPUT); // Enable internal pull-up resistor on pin 21
	pinMode(BrakePin, INPUT);// Enable internal pull-up resistor on pin 20
}

#pragma endregion

