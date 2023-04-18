#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;
const byte SDA_pin = 20;
const byte SCL_pin = 21;

const byte home_out = 47;

// I2C variables
volatile int Wire_received = 0; //edited
byte motor_positions = 0;
byte readpointer = 0;
byte writepointer = 0;
byte value_received = 0;

void setup ()
{
  // Initialize control pins
  pinMode(home_out, OUTPUT);
  digitalWrite(home_out, LOW);
  
  // I2C setup
  Wire_received = 0; //edited
  readpointer = 0;
  writepointer = 0;
  Wire.begin(7); // join I2C bus with address/ 7 (Motor1)
  //Wire.begin(8); // join I2C bus with address 7 (Motor2)
  Wire.onReceive(receiveEvent);

  Serial.begin(115200);
}

void receiveEvent(int howmany) // I2C interrupt routine
{
  for (int j = 0; j < howmany; j++)
  {
    byte c = Wire.read();
    motor_positions = c;
  }
  Wire_received = Wire_received + 1; //edited
}  // end of interrupt routine

void loop ()
{
  //Serial.println(motor_positions); // transmit to Arduino

  if (Wire_received > 0) //edited
  {
    digitalWrite(home_out,motor_positions == 131);
    Serial.println(motor_positions); // transmit to Arduino
    //readpointer = (readpointer + 1) % 10;
    Wire_received = Wire_received - 1; //edited
  }
}
