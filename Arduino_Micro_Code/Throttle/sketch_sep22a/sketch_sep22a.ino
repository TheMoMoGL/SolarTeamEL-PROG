int ReadThrottlePin =0;
int ThrottlePin=3;

int Throttle=0;

void setup() {
  
}

void loop() {
  
  // Get throttle from analog pin 0
  Throttle = analogRead(ReadThrottlePin);
  Throttle = map(Throttle, 0, 1023, 0, 255);
  
  // Set throttle to digital pin 2
  analogWrite(ThrottlePin, Throttle);

}
