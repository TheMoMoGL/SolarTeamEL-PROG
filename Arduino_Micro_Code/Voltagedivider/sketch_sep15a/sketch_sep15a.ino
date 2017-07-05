int sensorPin=0;
int sensorValue=0;
int maxVoltage=45;
int voltage=0;

void setup() {

  Serial.begin(9600);
  DDRA = 0b11111111;  //Set port A as output, pin 22-29

}

void loop() {

  sensorValue = analogRead(sensorPin);
  voltage = sensorValue * (5.0 / 1023.0) * 9;
  Serial.println(voltage);
  delay(1000);
  PORTA=voltage;

}
