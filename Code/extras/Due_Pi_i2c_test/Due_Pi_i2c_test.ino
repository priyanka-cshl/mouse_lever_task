#include <Wire.h>
#include <DueTimer.h>

const byte SDA_pin = 20;
const byte SCL_pin = 21;
int motor1_i2c_address = 0x13;
byte Val2Send = 0;

void setup() {
  // put your setup code here, to run once:
  Wire.begin();

  Timer3.attachInterrupt(MoveBar);
  Timer3.start(1000 * 10); // Calls every 10 msec

}

void loop() {
  // put your main code here, to run repeatedly:
}

void MoveBar() {
  if (Val2Send>9){
    I2Cwriter(motor1_i2c_address,Val2Send);
  }
  Val2Send = Val2Send + 1;
}

void I2Cwriter (int wire_address, int DataToWrite)
{
  Wire.beginTransmission(wire_address);
  Wire.write(DataToWrite);
  Wire.endTransmission();
}
