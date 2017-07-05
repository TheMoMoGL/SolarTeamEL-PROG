#include <SoftwareSerial.h>

SoftwareSerial mySerial(A12, 44); // RX, TX

void setup() {

  Serial.begin(9600);
  mySerial.begin(9600);
}

void loop() { 
  
  if(Serial.available()){
    if(Serial.read()=='P'){
    Serial.println(GetSpeed());
    }
  }

}

int GetSpeed(){
  
  mySerial.write('S');
  while(!mySerial.available());
  return mySerial.read();
  
  }
