/* 
  
  Brake
  input - digital pin 5
  
*/
int BrakePin = 3;             // Digital pin 5 | Digital pin 3      - Break
int CruisePin = 4;            // Digital pin 3 | Digital pin 24    - Cruise
uint8_t   Cruise        = 0;


boolean   Edit          = false;
boolean   Break         = false;
boolean   Deactivated   = false;

void setup() {

  pinMode(BrakePin, INPUT);
  pinMode(CruisePin, INPUT);
  pinMode(13, OUTPUT);
  digitalWrite(13, LOW);
  
}

void loop() {
    
  CruiseControl();

}

void CruiseControl(){
  
  if(Cruise==1 && Deactivated){
    digitalWrite(13, HIGH);
  }else{
    digitalWrite(13, LOW);
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
