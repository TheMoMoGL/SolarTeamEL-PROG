auto DO_NOT_REMOVE_THIS = 0;
/*
* Program:  SolarCarSystem
* --------------------
* this is the brain of the car, it communicate with another
*			arduino to get the speed, then based on the speed
*			it will run PID and other calculation, it is also
*			alwayse listening to xbee serial port for incomming
*			commands, then it will act on them, for example
*			one can read speed, PID values, cruse control status,
*			can messeges and so forth, as well as update values
*
*  circuts: extension, xbee shield, CAN shield:
*			this code is optimized for arduino mega, then the
*			extension is attached to it, then the xbee and finally
*			can shield. Car's communciation system is based on can bus
*			based on the speed of that can, the can shield on this
*			ardunio should be configured and the interested messege IDs
*			should be hard coded as well.
*
*  returns: all the information about car, such as battry status,
*			can messeges, speed, PID values and so forth
*/

#pragma region Includes
#include <HardwareSerial.h>
#include "SerialCommand.h"
#include "Configuration.h"
#include <string.h>
#include "mcp2515.h"
#include "mcp2515_defs.h"
#include "global.h"
#include "defaults.h"
#include "Canbus.h"
#include <SPI.h>
#include <SD.h>
#include <LiquidCrystal.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>

#pragma endregion

#pragma region Declarations

#pragma region Communication Vars

bool CAN_INITIALIZED = false;
HardwareSerial *HardSerial_xBeeToxBee = &Serial;
HardwareSerial *HardSerial_ArduinoToArduino = &Serial2;
//SoftwareSerial testSerial(A12, 44); //rx, tx
SerialCommand Commands_xBeeToxBee(*HardSerial_xBeeToxBee, false);

#pragma endregion

#pragma region CAN & SD Card

const uint8_t chipSelect = 8;
char buffer[456];
boolean DoLogging = true;
int Delay1 = 0;
int Delay2 = 1001;
int LoggingTime = 1000;
bool PrintHeader = true;

struct LogStruct {

	int Velocity;
	int Throttle;
	int Pvalue;
	int Ivalue;
	int Dvalue;
	int CruiseControlOn;
	int CANmsg1;
};
LogStruct LogMsg;

#pragma endregion

#pragma region LCD & PID Vars

const uint16_t ReadThrottlePin = 15;       // Analog pin 1   | Analog pin 15       - Th_in
const uint16_t CruisePin = 24;             // Digital pin 3  | Digital pin 24      - Cruise
const uint16_t ThrottlePin = 3;// 46;           // Digital pin 4  | Digital pin 46      - Th_out
const uint16_t BrakePin = 4;

const uint16_t c_updateTime = 500;
const uint16_t d_updateTime = 500;
unsigned long cDelay1 = 0;
unsigned long cDelay2 = 0;
unsigned long dDelay1 = 0;
unsigned long dDelay2 = 0;

LiquidCrystal lcd(36, 34, 32, 30, 28, 26);

String Line11 = "Speed  : ";
String Line12 = " km/h  ";

String Line21 = "BatWarn: ";
String BatteryWarnings = "NONE";
String Line31 = "BatPwr : ";
String Line32 = " Volt  ";
String Line41 = "CruiseC: ";
String Line42 = "OFF";
uint16_t Increment = 0;
volatile int Speed = 0;   //kolla upp om det ska vara kopplad till ett arduino. // funkar det så blir det check
const float alphaValue = 0.5;
uint16_t Throttle = 0;
uint16_t CruiseSpeed = 0;
uint16_t Cruise = 0;
uint16_t BatPwr = 0;
boolean CC_ON = false;
int	Last = 0;
int Error = 0;
int Integral = 0;
int IntThresh = 40;
float ScaleFactor = 0.1;
int kP = 5;
int kI = 40;
int kD = 0;

#pragma endregion

#pragma endregion

#pragma region Arduino Setup/Loop

/*
* Function:  setup
* --------------------
* arduino's main setup section:
*    it will call all the configuration of serial ports
*    SD card, CAN and so forth, if you want to test something
*	 you can comment each section, if you comment the xbee
*	 setup make sure you comment the print messeges using
*    this port, which are sent via xbee to matlab system
*
*  returns: nothing
*/
void setup()
{
	//setupUSBPort();
	setupXbee2XbeeSerialPort();
	setupArduino2ArduinoSerialPort();
	setupxBeeCommandSet();
	//setupDebug();
	setupSD();
	setupCANBus();
	setupPIDandLCD();
}

/*
* Function:  loop
* --------------------
* arduino's main loop section:
*    it will run continusely and check the incomming commands
*    over xbee, plus it will check the time and update the LCD
*	 every specefic time period, crusie control and logging
*	 will be called as well, be aware that incomming speed value
*    is comming over serialEvent and that function will occure
*    in conjution with loop, not exactly pure interrup wise.
*
*  returns: nothing
*/
void loop()
{

	//PID & Speed Updates
	noInterrupts();
	if (cDelay1 == 0) {
		cDelay1 = millis();
	}

	if (dDelay1 == 0) {
		dDelay1 = millis();
	}


	dDelay2 = millis();
	if (dDelay2 - dDelay1 > d_updateTime) {
		dDelay1 = 0;
		dDelay2 = 0;
		CruiseControl();
	}

	cDelay2 = millis();
	if (cDelay2 - cDelay1 > c_updateTime) {
		Increment++;
		cDelay1 = 0;
		cDelay2 = 0;
		DisplayState(Increment);

	}
	
	interrupts();
	serialEvent2();
	Commands_xBeeToxBee.readSerial();
	startLogging();
	
}
#pragma endregion

#pragma region Setup Serial, Xbee, LCD, CAN & SD Card

/*
* Function:  setupUSBPort
* --------------------
* this is to print the data through USB for testing
*
*  returns: nothing
*/
void setupUSBPort()
{
	Serial.begin(XBEE_BUAD_RATE);
	//Serial.println("USB initialized");
}

/*
* Function:  setupXbee2XbeeSerialPort
* --------------------
* setting up xbee serial port with:
*    the xbee buadrate is very important it should be set
*    to the same value as the router xbee which is 9600
*	 in this case, any changes should be taken into both part.
*
*  returns: nothing
*/
void setupXbee2XbeeSerialPort()
{
	HardSerial_xBeeToxBee->begin(XBEE_BUAD_RATE);
	HardSerial_xBeeToxBee->println("Xbee serial initialized.");
}

/*
* Function:  setupArduino2ArduinoSerialPort
* --------------------
* setting up hardware serial port between two arduinos:
*    maximum buadrate is used to communicate between
*    arduino micro and mega for transferring speed
*	 values, 250k bps
*
*  returns: nothing
*/
void setupArduino2ArduinoSerialPort()
{
	//HardSerial_ArduinoToArduino->begin(HARD_SERIAL_BUAD_RATE);
	HardSerial_ArduinoToArduino->begin(9600);
	HardSerial_xBeeToxBee->println("Arduino serial initialized.");
	//Serial.println("Arduino serial initialized");
	//testSerial.begin(9600);
}


/*
* Function:  setupCANBus
* --------------------
* setting up CAN bus system:
*    maximum speed is used here which need to be the same
*    as the main buss system in the real car after implementation
*
*  returns: nothing
*/
void setupCANBus()
{
	HardSerial_xBeeToxBee->println("Setting up CAN.");
	//Serial.println("Setting up CAN");
	if (Canbus.init(CANSPEED_500))
	{
		HardSerial_xBeeToxBee->println("CAN Init Ok.");
		//Serial.println("CAN Init Ok");
		CAN_INITIALIZED = true;
	}
	else
	{
		HardSerial_xBeeToxBee->println("Can't init CAN.");
		//Serial.println("Can't init CAN");
		CAN_INITIALIZED = false;
	}
}

/*
* Function:  setupSD
* --------------------
* setting up SD card:
*    will setup the SD card pins, and output a success messge
*    depending on arduino board chipSelect and SS pin should be revised
*
*  returns: nothing
*/
void setupSD()
{
	HardSerial_xBeeToxBee->println("Setting up SD.");
	//Serial.println("Setting up SD");
	pinMode(chipSelect, OUTPUT);
	//pinMode(SS, OUTPUT);
	if (!SD.begin(chipSelect)) {
		HardSerial_xBeeToxBee->println("Card failed, or not present.");
		//Serial.println("Card failed, or not present");
		return;
	}

	HardSerial_xBeeToxBee->println("SD initialized.");
	//Serial.println("SD initialized.");
}

/*
* Function:  setupxBeeCommandSet
* --------------------
* adds all the commands to the system:
*    you need to add the command that you like to the system
*    like the sample:
*	 Commands_xBeeToxBee.addCommand("ON", LED_on);
*	 "ON" is the keyword to invoke it, and LED_on is the name
*    of the function that will be invoke, arduin's main look
*    constantly listen to incomming command via xbee and if
*    the keywords matches it will executes that function,
*    if the command does not exist, then then default handler
*    (unrecognizedCommand) will be executed:
*	 Commands_xBeeToxBee.addDefaultHandler(unrecognizedCommand);
*
*
*  returns: the callback functions
*/
void setupxBeeCommandSet()
{
	Commands_xBeeToxBee.addCommand("ON", LED_on);
	Commands_xBeeToxBee.addCommand("OFF", LED_off);
	Commands_xBeeToxBee.addCommand("GETSP", getSpeed);
	Commands_xBeeToxBee.addCommand("GETTT", getThrottle);
	Commands_xBeeToxBee.addCommand("TT", updateThrottle);
	Commands_xBeeToxBee.addCommand("CC", updateCruseSpeed);
	Commands_xBeeToxBee.addCommand("ECC", enableCruseControl);
	Commands_xBeeToxBee.addCommand("DCC", disableCruseControl);
	Commands_xBeeToxBee.addCommand("GETCC", getCruseControlStatus);
	Commands_xBeeToxBee.addCommand("CCSP", getCruseControlSpeed);
	Commands_xBeeToxBee.addCommand("P", updatePID_P);
	Commands_xBeeToxBee.addCommand("I", updatePID_I);
	Commands_xBeeToxBee.addCommand("D", updatePID_D);
	Commands_xBeeToxBee.addCommand("PID", getPID);
	Commands_xBeeToxBee.addCommand("EL", enableLogging);
	Commands_xBeeToxBee.addCommand("DL", disableLogging);
	Commands_xBeeToxBee.addCommand("GETL", getLoggingStatus);
	Commands_xBeeToxBee.addCommand("CINFO", getCarInfo);
	
	Commands_xBeeToxBee.addDefaultHandler(unrecognizedCommand);
	HardSerial_xBeeToxBee->println("Commands Set added.");
}

/*
* Function:  setupPIDandLCD
* --------------------
* sets all the pins for different input and output messeges:
*    input pins are cruise, brake and read throttle pin
*	 the output pin is throttle which will set the speed of car
*    second part initialze the LCD configuration and
*	 update set the cursor to its start point
*
*  returns: nothing
*/
void setupPIDandLCD()
{
	pinMode(CruisePin, INPUT);
	pinMode(BrakePin, INPUT);
	pinMode(ThrottlePin, OUTPUT);
	pinMode(ReadThrottlePin, INPUT);
	HardSerial_xBeeToxBee->println("PID initialized.");
	//Serial.println("PID initialized.");

	lcd.begin(20, 4);
	lcd.print("Start");
	DisplayState(Increment);
	HardSerial_xBeeToxBee->println("LCD initialized.");
	//Serial.println("LCD initialized.");
}

/*
* Function:  setupDebug
* --------------------
* this part configure the arduinos debug led
*
*  returns: nothing
*/
void setupDebug()
{
	pinMode(ARDUINO_DEBUG_LED, OUTPUT);
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
}

/*
* Function:  RetrieveAnalogValues
* --------------------
* call this method before logging to update all the variables and
*	put them in the logMsg for logging
*
*  returns: nothing
*/
void RetrieveAnalogValues() {

	LogMsg.Velocity = Speed;
	LogMsg.Throttle = Throttle;
	LogMsg.Pvalue = kP;
	LogMsg.Ivalue = kI;
	LogMsg.Dvalue = kD;
	LogMsg.CruiseControlOn = Cruise;
}

#pragma endregion

#pragma region Callback Functions (Command Set)

/*
* Function:  LED_on
* --------------------
* this method will be called once a ON Command from xbee recived
*    it will turn on the LED on arduino and send a messege via xbee
*
*  returns: nothing
*/
void LED_on()
{
	digitalWrite(ARDUINO_DEBUG_LED, HIGH);
	HardSerial_xBeeToxBee->println("LED is ON");
}

/*
* Function:  LED_off
* --------------------
* this method will be called once a OFF Command from xbee recived
*    it will turn off the LED on arduino and send a messege via xbee
*
*  returns: nothing
*/
void LED_off()
{
	digitalWrite(ARDUINO_DEBUG_LED, LOW);
	HardSerial_xBeeToxBee->println("LED is OFF");
}

/*
* Function:  getSpeed
* --------------------
* this method will be called once a GETSP Command from xbee recived
*    it will make a messege in this format S15S which encapulate
*	 speed value between S and S, later it will be send to xbee
*
*  returns: nothing
*/
void getSpeed()
{
	char* strSpeed;
	strSpeed = int2str(Speed);
	String msg = MSG_HEADER_SPEED;
	msg += strSpeed;
	msg += MSG_FOOTER_SPEED;
	HardSerial_xBeeToxBee->println(msg);
}

/*
* Function:  updateCruseSpeed
* --------------------
* this method will be called once a CC Command from xbee recived
*    it will update the cruise speed accroding incoming value
*	 and echo back if everythings ok.
*
*  returns: nothing
*/
void updateCruseSpeed()
{
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);
		CruiseSpeed = aNumber;
		HardSerial_xBeeToxBee->println(CruiseSpeed);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
}

/*
* Function:  updateThrottle
* --------------------
* this method will be called once a TT Command from xbee recived
*    it will update the throttle value directly and send to motor
*
*  returns: nothing
*/
void updateThrottle()
{
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);
		Throttle = aNumber;
		HardSerial_xBeeToxBee->println(Throttle);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
}

/*
* Function:  getThrottle
* --------------------
* this method will be called once a GETTT Command from xbee recived
*    it will make a messege in this format T15T which encapulate
*	 throttle value between T and T, later it will be send to xbee
*
*  returns: nothing
*/
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
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);
		kP = aNumber;
		HardSerial_xBeeToxBee->println(kP);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}

}

void updatePID_I()
{
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);
		kI = aNumber;
		HardSerial_xBeeToxBee->println(kI);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
}

void updatePID_D()
{
	int aNumber;
	char *arg;

	arg = Commands_xBeeToxBee.next();
	if (arg != NULL)
	{
		aNumber = atoi(arg);
		kD = aNumber;
		HardSerial_xBeeToxBee->println(kD);
	}
	else {
		HardSerial_xBeeToxBee->println("No arguments");
	}
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

void enableCruseControl()
{
	Cruise = 1;
	CC_ON = true;  // var false innan (MV)
	HardSerial_xBeeToxBee->println("CC Enabled");
}

void disableCruseControl()
{
	Cruise = 0;
	CC_ON = false;  // var true innan (MV)
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

void unrecognizedCommand()
{
	HardSerial_xBeeToxBee->println("Unrecognized command");
}

void flushArduino2ArduinoReceiveBuffer()
{
	while (HardSerial_ArduinoToArduino->available()) HardSerial_ArduinoToArduino->read();
}

void enableLogging()
{
	DoLogging = true;
	HardSerial_xBeeToxBee->println("Logging enabled");
}

void disableLogging()
{
	DoLogging = false;
	HardSerial_xBeeToxBee->println("Logging disabled");
}

void getLoggingStatus()
{
	char lStatus = DoLogging == true ? '1' : '0';
	String msg = MSG_HEADER_LOGGING;
	msg += lStatus;
	msg += MSG_FOOTER_LOGGING;
	HardSerial_xBeeToxBee->println(msg);
}

void getCarInfo()
{
	char* speed = int2str(Speed);
	String msg = MSG_HEADER_CAR;
	msg += speed;
	msg += MSG_SEPERATOR;
	char* cSpeed = int2str(CruiseSpeed);
	msg += cSpeed;
	msg += MSG_SEPERATOR;
	char* collectedSolarPower = int2str(random(400, 1000));
	msg += collectedSolarPower;
	msg += MSG_SEPERATOR;
	char* chargeState = "500";
	msg += chargeState;
	msg += MSG_FOOTER_CAR;
	HardSerial_xBeeToxBee->println(msg);
}

#pragma endregion

#pragma region	CAN Bus Reader

void resetCANVariables()
{
	// Reset all the CAN variables between logging so that we only log the retrieved data when we just retrieved it.
	LogMsg.CANmsg1 = 0;
}

void checkCan()
{
	while (mcp2515_check_message())
	{
		Canbus.ecu_req(THROTTLE, buffer);
		LogMsg.Throttle = (int)buffer;
	}
}

#pragma endregion

#pragma region LCD & PID Codes

/*
* Function:  PID_controller
* --------------------
* Throttle control system:
*    Depending on the P and I values, the controller will adjust
*    the speed until it reaches the Cruise speed. Dont be
*    missled by the name PID controller, as it is only a
*    PI controller.
*
*  returns: nothing
*/

int PID_controller()
{
	Error = CruiseSpeed - Speed;

	if (Integral < IntThresh) {                     // prevent integral 'windup'
		Integral = Integral + Error;                    // accumulate the error integral
	}
	else {
		Integral = 0;                                   // zero it if out of bounds
	}
	float P = Error*(float)kP*0.01;                    // calc proportional term
	float I = Integral*(float)kI*0.01*(1/d_updateTime);                 // integral term
	Throttle = Throttle + (P + I) * Throttle;                  // Total drive = P+I
	if (Throttle > 255)
	{
		Throttle = 255;
	}
	else if (Throttle < 0) {
		Throttle = 0;
	}
	Last = Speed;

	return Throttle;
}

/*
* Function:  DisplayState
* --------------------
* Display current settings on LCD:
*    Depending on the input integer either the whole LCD is updated
*    or just the individual parameters
*
*  returns: nothing
*/

void DisplayState(int Increment)
{
	if (0 == (Increment % 10))
	{
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
	else
	{
		lcd.setCursor(9, 0);
		lcd.print(Speed + Line12);
		lcd.setCursor(9, 1);
		lcd.print(BatteryWarnings);
		lcd.setCursor(9, 2);
		lcd.print(Throttle + Line32);
		lcd.setCursor(9, 3);
		lcd.print(Line42);
	}
}

/*
* Function:  Clear
* --------------------
* Clear the LCD:
*    Clears every single character on the 20 by 4 LCD display
*
*  returns: nothing
*/

void Clear()
{
	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 20; j++)
		{
			lcd.setCursor(j, i);
			lcd.print(" ");
		}
	}
}

/*
* Function:  CruiseControl
* --------------------
* Checks if cruise control is activated:
*    If cruise control is activated on the cruise button, cruise control will only
*    turn on if cruise control has been activated before turned on. This functionality
*    orginates from the possible deactivation from the brake, if someone brakes
*    cruise control must be deactivated even if the cruise button is still in an active
*    state.
*
*    If cruise control is activated, the throttle will go through the PID control.
*
*    Otherwise it will go through the throttle grip.
*
*  returns: nothing
*/

/*void CruiseControl() {
	
	if (digitalRead(CruisePin) == HIGH) {
		Cruise = 1;
		CC_ON = true;
	}
	else {
		Cruise = 0;
		CC_ON = False; 
	}
	if (digitalRead(BrakePin) == HIGH) {
		CC_ON = False;
		Cruise = 0;
	}
	if (Cruise == 1 && CC_ON) {
		Line42 = "ON ";
		analogWrite(ThrottlePin, PID_controller());
	}
	else {
		Line42 = "OFF";
		Throttle = analogRead(ReadThrottlePin);
		Throttle = map(Throttle, 0, 1023, -50, 300);
		analogWrite(ThrottlePin, Throttle);
	}
	
}*/
void CruiseControl() {


	/* digitalRead(CruisePin) is 1 (HIGH) if driver enables CC and 0 (LOW) if disabled, 
	this way the driver gets the initial control over CC, if the driver brakes, the CC
	is automaticlly disabled
	
	The next step is to enable the CC from matlab with the commandline "ECC", this can only
	be done if the driver has enabled the CC first. */

	if (digitalRead(BrakePin) == 1) {
		Cruise = 0;
	}

	if (digitalRead(CruisePin) == 1) {
		if (Cruise == 1) {
			Line42 = "ON ";
			analogWrite(ThrottlePin, PID_controller());
		}
		else if (Cruise == 0) {
			Line42 = "RDY";

			Throttle = analogRead(ReadThrottlePin);
			Throttle = map(Throttle, 0, 1023, 0, 255);
			analogWrite(ThrottlePin, Throttle);
			
		}
	}
	else {
		Cruise = 0;
		Line42 = "OFF";
		
		Throttle = analogRead(ReadThrottlePin);
		Throttle = map(Throttle, 0, 1023, 0, 255);
		analogWrite(ThrottlePin, Throttle);
	}
}


#pragma endregion

#pragma region SD Code

void startLogging()
{
	if (DoLogging)
	{
		//checkCan();
		logData();
	}
}

void printHeaderFunction()
{
	char buffer[456];
	int HeaderLenght = sprintf(buffer, "Timestamp,  Velocity,  Throttle, P-value, I-value, D-value,  CruiseControlOn,  CANmsg1");
	writeToSD(buffer, HeaderLenght);
	PrintHeader = false;
}

void writeToSD(char *Text, int num_char)
{
	File dataFile = SD.open("datalog.txt", FILE_WRITE);
	if (dataFile)
	{
		dataFile.write(Text, num_char);
		dataFile.close();
	}
	else
	{
		HardSerial_xBeeToxBee->println("error opening log file.");
		DoLogging = false;
	}
}

void logData()
{

	Delay2 = millis();
	if (Delay2 - Delay1 > LoggingTime)
	{
		Delay1 = millis();

		//Only print a header on start up
		if (PrintHeader)
			printHeaderFunction();

		unsigned int timeStamp = millis() / 1000;
		RetrieveAnalogValues();

		char buffer[456];
		int num_char = sprintf(buffer, "%d  s,    %d,        %d,      %d,       %d,      %d,      %d,       %d\n",
			(unsigned int)timeStamp, (int)LogMsg.Velocity, (int)LogMsg.Throttle, (int)LogMsg.Pvalue,
			(int)LogMsg.Ivalue, LogMsg.Dvalue, (int)LogMsg.CruiseControlOn, (int)LogMsg.CANmsg1);
		writeToSD(buffer, num_char);

		resetCANVariables();
	}
}

#pragma endregion

#pragma region Arduino 2 Arduino Code


void serialEvent2()
{
	//http://damienclarke.me/code/posts/writing-a-better-noise-reducing-analogread


	//while (testSerial.available())
	//{
	//	Speed = testSerial.read();

	//	testSerial.print("speed ");
	//	testSerial.print(Speed);

	//	//Speed += (HardSerial_ArduinoToArduino->read() - Speed) * alphaValue;
	//	//Speed = HardSerial_ArduinoToArduino->read();
	//}



	if (HardSerial_ArduinoToArduino->available())
	{
		Speed = HardSerial_ArduinoToArduino->read();


		//Speed += (HardSerial_ArduinoToArduino->read() - Speed) * alphaValue;
		//Speed = HardSerial_ArduinoToArduino->read();
	}
}

#pragma endregion

#pragma region Helpers Funcs

char _int2str[7];
/*
* Function:  int2str
* --------------------
* this function convert any int to string values
*    this is used to make up messege systems
*    like S100S which will be send via serial
*	 and means speed = 100
*  returns: stirng of int
*/
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
