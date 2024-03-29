// This optional setting causes Encoder to use more optimized code,
// It must be defined before Encoder.h is included.
#include <Encoder.h>

// declare pins
Encoder RotaryEncoder(11, 12);
int home_pin = 25;
volatile int rotary_position = 0;
IntervalTimer DACOUTTimer;

void setup() {
  // put your setup code here, to run once:
  pinMode(home_pin,INPUT);
  analogWriteResolution(12);
  DACOUTTimer.begin(WritePosition, 2000); // every 2 msec
  Serial.begin(9600);
}

void home_interrupt()
{
  RotaryEncoder.write(0);
  rotary_position = 0;
}

void WritePosition()
{
  analogWrite(A22,2000+rotary_position);
}

void loop() {
  // put your main code here, to run repeatedly:
  rotary_position = RotaryEncoder.read();
  Serial.println(rotary_position);
}
