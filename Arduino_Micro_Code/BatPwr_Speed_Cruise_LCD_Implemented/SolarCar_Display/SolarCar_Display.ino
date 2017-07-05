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

  VoltageDivider
  input - analog 0

  Hall sensor
  input - ISR digital pin 2

  Cruise control
  input - digital pin 3
*/

#include <LiquidCrystal.h>

#define Radius 0.18f
#define Magnets 3.0f
#define StartWatch 0
#define StopWatch 1
#define Standby 2

int BatPin = 0;
int interruptPin = 2;
int CruisePin = 3;

unsigned long T1, T2, D, Delay1=0, Delay2=0;
char State = 0;
unsigned long Factor = 3.6f * PI * Radius * 1000000.0f / Magnets;

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(13, 12, 11, 10, 9, 8);

String Line11 = "Speed : ";
String Line12 = " km/h";

String Line21 = "BatWrn: ";

String Line31 = "BatPwr: ";
String Line32 = " Volt";

String Line41 = "CruiseControl: ";
String Line42 = "OFF";

int Speed = 0;
int BatPwr = 100;
String BatteryWarnings = " NONE";


void setup() {
  
  lcd.begin(20, 4);     // set up the LCD's number of columns and rows:
  lcd.print("Start");   // Print a message to the LCD.
  
  pinMode(interruptPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(interruptPin), Change, RISING);

  pinMode(CruisePin, INPUT);
  
}

void loop() {

  if(Delay1==0){
    Delay1 = millis();
  }
  
  if(digitalRead(CruisePin)==HIGH){
      Line42="ON";
  }else{
      Line42="OFF";
  }

  BatPwr = analogRead(BatPin) * (5.0 / 1023.0) * 9;

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

  Delay2= millis();
  if(Delay2-Delay1 > 500){
    DisplayState();
    Delay1=0;
    Delay2=0;
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
    
      lcd.setCursor(0, 0);
  lcd.print(Line11+Speed+Line12);
  
  lcd.setCursor(0, 1);
  lcd.print(Line21+BatteryWarnings);
  
  lcd.setCursor(0, 2);
  lcd.print(Line31+BatPwr+Line32);
  
  lcd.setCursor(0, 3);
  lcd.print(Line41+Line42);
    
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

void Change(){
  
  if (State == Standby){
    State = StopWatch;
  }
}

