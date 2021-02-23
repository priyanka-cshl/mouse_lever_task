#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// motor control pins
const byte SDA_pin = 20;
const byte SCL_pin = 21;
bool motor_ON = false;
int home_location = 121;
bool cheat = false;

// motor position variables
int desired_location = home_location;
int current_location = home_location;
int delta_steps = 0;
volatile int current_direction = 1; // CW
int stepsize = 1; // motor location is between 1-50, steps allowed = 200 = quarter turn for the motor

// motor timing variables
int dir_wait = 100; // in uS - time to wait before executing a step, after direction is switched
int step_wait = 10; // in uS - time to wait before toggling the step_pin

// motor status
volatile bool busy = 0;
volatile bool homing = 0;

// SPI variables
volatile int Wire_received = 0; //edited
byte motor_positions = 0;
byte readpointer = 0;
byte writepointer = 0;
byte value_received = 0;

void setup ()
{
  // Initialize control pins

  // I2C setup
  Wire_received = 0; //edited
  readpointer = 0;
  writepointer = 0;
  Wire.begin(7); // join I2C bus with address/ 7 (Motor1)
  //Wire.begin(8); // join I2C bus with address 7 (Motor2)
  Wire.onReceive(receiveEvent);

  // debugging
 Serial.begin (115200);
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
  
  if (Wire_received > 0) //edited
  {
    Serial.println(motor_positions);
    //value_received = motor_positions[readpointer];
    value_received = motor_positions;
    //Serial.println(value_received);
    if (value_received >= 10)
    {
      desired_location = value_received - 10;
      delta_steps = stepsize * abs(desired_location - current_location);
      if ( delta_steps <= 50 )
      {
        step_wait = round(8000 / delta_steps);
      }
      else if ( delta_steps <= 80 ) 
      {
        step_wait = 100;
        //step_wait = round(6000 / delta_steps);
      }
      else
      {
        step_wait = 200;
      }
    }
    else
    {
      
    }
    //readpointer = (readpointer + 1) % 10;
    Wire_received = Wire_received - 1; //edited
  }
}
