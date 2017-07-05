#include <SoftwareSerial.h>

#define Radius 0.2f
#define Magnets 2.0f
#define StartWatch 0
#define StopWatch 1
#define Standby 2

const byte interruptPin = 3;
unsigned long T1, T2, D;
char State = 0;
int Speed=10;
int i = 0;
int arr[] = {0,0,0};
boolean Send = false;

//Factor is for converting km/h.
unsigned long Factor = 3.6f * PI * Radius * 1000000.0f / Magnets;

SoftwareSerial mySerial(10, 11); // RX, TX

void setup()
{

  mySerial.begin(9600);
  pinMode(interruptPin, INPUT);
  attachInterrupt(digitalPinToInterrupt(interruptPin), Change, RISING);
  
}

void loop(){
  
  if(micros()-T1>1000000){
    Speed=0;  
  } 
  
  if(Send){
    Speed = (arr[0]+arr[1]+arr[2])/3;
    arr[0]=0; arr[1]=0; arr[2]=0;
    Send = false;
  }

  if(mySerial.available()){
    if(mySerial.read()=='S'){
        mySerial.write(Speed);
    }
  }
}

void Change(){
  
  if (State == Standby){
    State = StopWatch;
  }

  switch (State){
    case StartWatch:
      T1 = micros ();
      State = Standby;
      break;
    case StopWatch:
      T2 = micros ();
      D = T2 - T1;
      arr[i]= Factor / D;
      i++;
      if(i>2){
        Send = true;
        i=0;
      }
      State = StartWatch;
      break;
  }
}
