unsigned long t1=0,t2=0;
volatile int rounds = 0;
boolean New = true;
float Om = 0.0;
float pi = 3.14;
float radius = 0.25;

const byte interruptPin = 2;

void setup() {

  Serial.begin(9600);
  pinMode(interruptPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(interruptPin), Change, RISING);
}

void loop() {

  if(New){
    t1=millis();
    New=!New;
  }
  t2=millis();

  if(t2-t1>=500){
    Om =pi*rounds*radius*1000; 
    int temp = Om/(t2-t1);
    Serial.print(temp);
    Serial.print(" m/s");
    Serial.print("    =    ");
    Serial.print(3.6*temp);
    Serial.println(" km/h");
    Serial.print(rounds);
    Serial.println(" passes");
    PORTA=3.6*temp;
    Serial.println(PINA);
    rounds=0;
    New=!New;
  }
}

void Change() {
  rounds++;
  
}
