// declare pins
int encoderA = 53;
int encoderB = 51;
int encoderZ = 49;
int home_pin = 47;
int DAC_pin = DAC0;
volatile int rotary_position = 0;
int position_sign = 1; // 1 = positive, -1 = negative;

int counter = 0;

void setup() {
  // put your setup code here, to run once:
  pinMode(encoderA,INPUT);
  pinMode(encoderB,INPUT);
  pinMode(home_pin,INPUT);
  analogWriteResolution(12);
  attachInterrupt(home_pin, home_interrupt, RISING) ; 
  attachInterrupt(encoderA,rotary,RISING);
  //Serial.begin(115200);
}

void home_interrupt()
{
  rotary_position = 0;
}

void rotary() // interrup routine for rising edge on encoderA
{
  rotary_position = rotary_position + (2*(digitalRead(encoderB)) - 1);
}

void loop() {
  // put your main code here, to run repeatedly:
  if (rotary_position<0)
  {
    position_sign = -1;
  }
  else
  {
    position_sign = 1;
  }
  // constrain rotary position between 0-1023
  rotary_position = abs(rotary_position) % 1024;
  rotary_position = rotary_position * position_sign;
  analogWrite(DAC_pin,3*(rotary_position+650));
  //Serial.println(rotary_position);
}
