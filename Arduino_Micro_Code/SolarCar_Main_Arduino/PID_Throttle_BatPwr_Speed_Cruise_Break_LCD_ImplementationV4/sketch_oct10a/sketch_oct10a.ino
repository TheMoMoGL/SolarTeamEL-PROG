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

#include <LiquidCrystal.h>
#include <SoftwareSerial.h>

#define Radius 0.16f
#define Magnets 1.5f
#define StartWatch 0
#define StopWatch 1
#define Standby 2
#define Update 500

int ReadThrottlePin = 15;       // Analog pin 1   | Analog pin 15       - Th_in
//int interruptPin = 3;           // Digital pin 2  | Digital pin 3       - Hall
int CruisePin = 24;             // Digital pin 3  | Digital pin 24      - Cruise
int ThrottlePin = 46;           // Digital pin 4  | Digital pin 46      - Th_out
int BrakePin = 4;               // Digital pin 5  | Digital pin 4       - Brake

unsigned long T0, T1, T2, D, Delay1=0, Delay2=0;
char State = 0;
unsigned long Factor = 3.6f * PI * Radius * 1000000.0f / Magnets;

// Initialize the library with the numbers of the interface pins
LiquidCrystal lcd(36,34,32,30,28,26);

// Initialize the speed serial communication
SoftwareSerial mySerial(A12, 44); // RX, TX

String Line11 = "Speed  : ";
String Line12 = " km/h  ";

String Line21 = "BatWarn: ";
String BatteryWarnings = "NONE";

String Line31 = "BatPwr : ";
String Line32 = " Volt  ";

String Line41 = "CruiseC: ";
String Line42 = "OFF";

uint8_t   Increment     = 0;
uint8_t   Speed         = 0;
int       Throttle      = 0;
uint8_t   CruiseSpeed   = 0;
uint8_t   Cruise        = 0;
int       BatPwr        = 0;
boolean   Deactivated   = true;

//*******PID**********//
int       Last = 0;
int       Error = 0;
int       Integral = 0;
int       IntThresh = 1000;
int       ScaleFactor = 1;

uint8_t   kP=1;
uint8_t   kI=1;

void setup() {
  
  lcd.begin(20, 4);     // set up the LCD's number of columns and rows:
  lcd.print("Start");   // Print a message to the LCD.

  Serial.begin(9600);

  mySerial.begin(9600);
  
  DisplayState(Increment);

  pinMode(CruisePin, INPUT);

  pinMode(BrakePin, INPUT);
  
}

void loop() {
    
  if(Delay1==0){
    Delay1 = millis();
  }

  CruiseControl();

  GetSpeed();

  Delay2=millis();
  if(Delay2-Delay1 > Update){
    Increment++;
    DisplayState(Increment);
    Delay1=0;
    Delay2=0;
  }

}

int PID_controller (){
  
  Error = CruiseSpeed - Speed;

  if (abs(Error) < IntThresh) {                     // prevent integral 'windup'
    Integral = Integral + Error;                    // accumulate the error integral
  }
  else {
    Integral = 0;                                     // zero it if out of bounds
  }
  float P = Error*(float)kP*0.1;                                // calc proportional term
  float I = Integral*(float)kI*0.1;                             // integral term
  Throttle = P + I + Throttle;                            // Total drive = P+I+D
  if (Throttle>255) {
    Throttle = 255;
  }
  else if (Throttle<0) {
    Throttle = 0;
  }
  Last = Speed;                                    // save current value for next time 

  return Throttle;
}
    
void DisplayState (int Increment){

  if(0 == Increment % 10){
    Clear();
    Increment=0;
    lcd.setCursor(0, 0);
    lcd.print(Line11+Speed+Line12);
    lcd.setCursor(0, 1);
    lcd.print(Line21+BatteryWarnings);
    lcd.setCursor(0, 2);
    lcd.print(Line31+BatPwr+Line32);
    lcd.setCursor(0, 3);
    lcd.print(Line41+Line42);
  }else{
    lcd.setCursor(9, 0);
    lcd.print(Speed+Line12);
    lcd.setCursor(9, 1);
    lcd.print(BatteryWarnings);
    lcd.setCursor(9, 2);
    lcd.print(BatPwr+Line32);
    lcd.setCursor(9, 3);
    lcd.print(Line42);
  }
}

void Clear(){
  for(int i=0; i<4; i++){
    for(int j=0; j<20; j++){
      lcd.setCursor(j, i);
      lcd.print(" ");
    }
  } 
}

void CruiseControl(){
    
  if(Cruise==1 && Deactivated){
    Line42="ON ";
    CruiseSpeed = Speed;
    analogWrite(ThrottlePin, PID_controller());
  }else{
    Line42="OFF";
    Throttle = analogRead(ReadThrottlePin);
    Throttle = map(Throttle, 0, 1023, 0, 255+35);   // 35 corresponds to 0.7V
    analogWrite(ThrottlePin, Throttle);
  }
  
  if(digitalRead(CruisePin)==HIGH){
    Cruise=1;
  }else{
    Cruise=0;
    Deactivated=true;
  }

  if(digitalRead(BrakePin)==HIGH){
    Deactivated=false;
  }
}

void GetSpeed(){
  
  mySerial.write('S');
  while(!mySerial.available());
  Speed = mySerial.read();
  Serial.println(Speed);
  
  }
