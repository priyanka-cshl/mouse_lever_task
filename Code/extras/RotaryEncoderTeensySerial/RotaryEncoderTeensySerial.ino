// This optional setting causes Encoder to use more optimized code,
// It must be defined before Encoder.h is included.
#include <Encoder.h>

// declare pins
//int encoderA = 11;
//int encoderB = 12;
Encoder RotaryEncoder(11, 12);
int encoderZ = 24;
int home_pin = 25;
volatile int rotary_position = 0;
int FSMheader = 0;

IntervalTimer SerialTimer;


void setup() {
  // put your setup code here, to run once:
//  pinMode(encoderA,INPUT);
//  pinMode(encoderB,INPUT);
  pinMode(home_pin,INPUT);
  analogWriteResolution(12);
  attachInterrupt(home_pin, home_interrupt, RISING) ; 
//  attachInterrupt(encoderA,rotary,RISING);
  //Serial.begin(152000);
  SerialTimer.begin(WritePosition, 2000); // every 2 msec
}

void home_interrupt()
{
  RotaryEncoder.write(0);
  //rotary_position = 0;
}

void WritePosition()
{
  //teensyUSB.writeUint16(rotary_position);
  analogWrite(A22,2000+rotary_position);
  //Serial.println(rotary_position);
}

void loop() {
  // put your main code here, to run repeatedly:
  rotary_position = RotaryEncoder.read();
}
