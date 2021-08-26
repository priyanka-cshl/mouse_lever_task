#include <Wire.h> // library for I2C communication - to slave Arduinos
#include <DueTimer.h>

const byte SDA_pin = 20;
const byte SCL_pin = 21;
int pi_i2c_address = 0x08;
byte piVal = 0;

void setup() {
  // put your setup code here, to run once:
  Wire.begin();
  Serial.begin(115200);
  Timer3.attachInterrupt(WriteI2C);
  Timer3.start(1000*10); // Calls every 10 msec
}

void loop() {
  // put your main code here, to run repeatedly:
  // I2Cwriter(pi_i2c_address,piVal);
//  piVal = (piVal + 1);
//  Serial.println(piVal);
//  delay(1);
}

void WriteI2C() {
  piVal = piVal + 1;
  I2Cwriter(pi_i2c_address,piVal);
  Serial.println(piVal);
}

void I2Cwriter (int wire_address, int DataToWrite)
{
  Wire.beginTransmission(wire_address);
  Wire.write(DataToWrite);
  Wire.endTransmission();
}
