/* Pin setup
  Vss - Gnd
  Vdd - 5V
  V0  - Contrast, potentiometer or 2.7kohm then Gnd
  Rs  - pin 13
  R/W - Gnd
  E   - pin 12
  D4  - pin 11
  D5  - pin 10
  D6  - pin 9
  D7  - pin 8
  A   - 5V (220ohm then 5V)
  K   - Gnd

  Battery Voltage
  input - analog pin 0

  Read Throttle
  input - analog pin 1

  Hall sensor
  input - ISR digital pin 2

  Cruise control
  input - digital pin 3

  Throttle control
  output - digital pin 4
  
  Break
  input - digital pin 5
  
*/

#include <LiquidCrystal.h>

#define Radius 0.16f
#define Magnets 1.5f
#define StartWatch 0
#define StopWatch 1
#define Standby 2

int BatPin = 0;               // Analog pin 0
int ReadThrottlePin = 1;      // Analog pin 1
int interruptPin = 2;         // Digital pin 2
int CruisePin = 3;            // Digital pin 3
int ThrottlePin = 4;          // Digital pin 4
int BreakPin = 5;             // Digital pin 5

unsigned long T0, T1, T2, D, Delay1=0, Delay2=0;
char State = 0;
unsigned long Factor = 3.6f * PI * Radius * 1000000.0f / Magnets;

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(13, 12, 11, 10, 9, 8);

String Line11 = "Speed  : ";
String Line12 = " km/h  ";

String Line21 = "BatWarn: ";
String BatteryWarnings = "NONE";

String Line31 = "BatPwr : ";
String Line32 = " Volt  ";

String Line41 = "CruiseC: ";
String Line42 = "OFF";

char      inByte;
uint8_t   Speed         = 0;
uint8_t   BatPwr        = 100;
int       Throttle      = 0;
uint8_t   CruiseSpeed   = 0;
uint8_t   Cruise        = 0;
boolean   Edit          = false;
boolean   Break         = false;
boolean   Deactivated   = true;

void setup() {

  Serial.begin(9600);
  
  lcd.begin(20, 4);     // set up the LCD's number of columns and rows:
  lcd.print("Start");   // Print a message to the LCD.
  
  DisplayState(1);
    
  pinMode(interruptPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(interruptPin), Change, RISING);

  pinMode(CruisePin, INPUT);

  pinMode(BreakPin, INPUT);
  
}

void loop() {

  if(Delay1==0){
    Delay1 = millis();
  }

  BatteryCheck();
  
  SerialResponse();

  CruiseControl();

  StateCheck();

  Delay2=millis();
  if(Delay2-Delay1 > 500){
    DisplayState(0);
    Delay1=0;
    Delay2=0;
  }

}

void SerialResponse(){
  
    if (Serial.available()) {
      
      if(Edit){
          Edit=false;
          while(!Serial.available()){}
          inByte = Serial.read();
          Throttle = inByte;
      }else{
        inByte = Serial.read();
        
        if(inByte=='A'){
          Serial.write(Cruise);
        }
        
        if(inByte=='C'){
          Serial.write(CruiseSpeed);
        }
        
        if(inByte=='S'){
          Serial.write(Speed);
        }
        
        if(inByte=='E'){
          Serial.write(Throttle);
        }
              
        if(inByte=='T'){
          Edit=true;
          DisplayState(0);
        }
      }
    }
}
    
void DisplayState (int FirstTime){

  if(FirstTime==1){
    
    Clear();
    
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

void BatteryCheck(){
  
  BatPwr = analogRead(BatPin) * (5.0 / 1023.0) * 9;
}

void CruiseControl(){
  
  if(Cruise==1){
    analogWrite(ThrottlePin, Throttle);
  }else{
    Throttle = analogRead(ReadThrottlePin);
    Throttle = map(Throttle, 0, 1023, 0, 255);
    analogWrite(ThrottlePin, Throttle);
  }

  if(digitalRead(BreakPin)==LOW && Deactivated){
    
    if(digitalRead(CruisePin)==HIGH && Cruise==0){
        Line42="ON ";
        Cruise=1;
        CruiseSpeed=Speed;
    }else if(digitalRead(CruisePin)==LOW){
        Cruise=0;
        Line42="OFF";
    }
  }else{
      
    if(digitalRead(CruisePin)==LOW){
      Deactivated = true;
    }else{
      Deactivated = false;
    }
  }
}

void StateCheck(){
  
  switch (State){
    case StartWatch:
      T1 = micros ();
      State = Standby;
      break;
    case StopWatch:
      T2 = micros ();
      D = T2 - T1;
      Speed = Factor / D;
      State = StartWatch;
      break;
  }   
}

void Change(){
  
  if (State == Standby){
    State = StopWatch;
  }
}

