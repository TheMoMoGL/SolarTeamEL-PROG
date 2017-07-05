#include <SoftwareSerial.h>

SoftwareSerial mySerial(10, 11); // RX, TX
int Speed=21;

void setup() {
  
  Serial.begin(57600);
  mySerial.begin(57600);
}

void loop() {

  if (mySerial.available()) {
    char Byte = mySerial.read();
    if(Byte=='S')
    mySerial.write(Speed);
    Serial.println(Speed);
  }
    
}
