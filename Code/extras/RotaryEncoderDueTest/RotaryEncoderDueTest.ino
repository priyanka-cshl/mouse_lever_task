// ---- adding libraries ------------------------------------------------------
#include <Encoder.h>
// ----------------------------------------------------------------------------

// rotary encoder
Encoder RotaryEncoder(9, 10);
int rotary_out = DAC0;
int home_pin = 13;
volatile int rotary_position = 0;

void setup()
{
  SerialUSB.begin(115200);

 // rotary encoder
  pinMode(home_pin,INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(home_pin), ZeroMotor, FALLING);
}


void loop()
{
  rotary_position = RotaryEncoder.read();
  SerialUSB.println(rotary_position);
  analogWrite(rotary_out,2000+rotary_position);
} // end of loop()

void ZeroMotor()
{
  RotaryEncoder.write(0);
  rotary_position = 0;
}
