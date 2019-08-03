#include <Encoder.h>

Encoder RotaryEncoder(9, 10);
int rotary_out = DAC0;
int home_pin = 13;
volatile int rotary_position = 0;

void setup() {
  // put your setup code here, to run once:
  SerialUSB.begin(115200);
  analogWriteResolution(12);
  pinMode(home_pin,INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(home_pin), ZeroMotor, FALLING);
}

void loop() {
  SerialUSB.println("oh well");
  // put your main code here, to run repeatedly:
  if (RotaryEncoder.read() != rotary_position)
  {
    rotary_position = RotaryEncoder.read();
    SerialUSB.println(rotary_position);
    
  }
  analogWrite(rotary_out,1500+rotary_position);
}

void ZeroMotor()
{
  RotaryEncoder.write(0);
  rotary_position = 0;
}
