#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// motor control pins
int enable_pin = 23;
int dir_pin = 25;
int step_pin = 27;
int home_pin = 31;

// motor position variables
int home_location = 0;
int desired_location = 0;
int current_location = 0;
int delta_steps = 0;
int current_direction = 1; // CW
int stepsize = 4; // motor location is between 1-50, steps allowed = 200 = quarter turn for the motor

// motor timing variables
int dir_wait = 100; // in uS - time to wait before executing a step, after direction is switched  
int step_wait = 10; // in uS - time to wait before toggling the step_pin

// motor status
bool busy = 0;

// SPI variables
volatile int Wire_received = 0; //edited
byte motor_positions[10] = {0,0,0,0,0,0,0,0,0,0};
byte readpointer = 0;
byte writepointer = 0;
byte value_received = 0;

void setup ()
{
  // Initialize control pins
  pinMode(enable_pin,OUTPUT);
  digitalWrite(enable_pin,LOW);
  pinMode(dir_pin,OUTPUT);
  digitalWrite(dir_pin,HIGH); // set to CW
  pinMode(step_pin,OUTPUT);
  digitalWrite(step_pin,LOW);
  pinMode(home_pin,INPUT);
  
  // I2C setup
  Wire_received = 0; //edited
  readpointer = 0;
  writepointer = 0;
  Wire.begin(7); // join I2C bus with address/ 7 (Motor1)
  //Wire.begin(8); // join I2C bus with address 7 (Motor1)
  Wire.onReceive(receiveEvent);

  // debugging
  // Serial.begin (115200);   
}

void receiveEvent(int howmany) // I2C interrupt routine
{
  //noInterrupts();
  for (int j = 0; j < howmany; j++)
  {
    byte c = Wire.read();
    motor_positions[writepointer] = c;
  }
  Wire_received = Wire_received + 1; //edited
  writepointer = (writepointer + 1) % 10;
}  // end of interrupt routine

void loop ()
{
  if (Wire_received > 0) //edited
  {
    value_received = motor_positions[readpointer];
    // Serial.println(value_received);
    if (value_received < 10)
    {
    	desired_location = value_received - 10;
      delta_steps = stepsize * abs(desired_location-current_location);
    	// calculate step time : max 10ms to make the move
    	if ( delta_steps <= 50 )
    	{
    		step_wait = round(5000/delta_steps);
    	}
    	else
    	{
    		step_wait = round(5000/delta_steps);
    	}
    }
    else
    {
    	Housekeeping(value_received);
    }
    readpointer = (readpointer + 1) % 10;
    Wire_received = Wire_received - 1; //edited
  }

  if ((current_location != desired_location) && !busy)
  {
    // check if the direction is correct, if not - switch direction
    if ((desired_location > current_location) != current_direction)
    {
      current_direction = !current_direction;
      digitalWrite(dir_pin, (bool)current_direction);
      delayMicroseconds(dir_wait);
    }
    // move now
    for (i=0; i<stepsize; i++)
    {
      digitalWrite(step_pin,HIGH);
      digitalWrite(step_pin,LOW);
      delayMicroseconds(step_wait);
    }
    // hack to increment current location: +1 if direction CW, -1 otherwise
    current_location = current_location + current_direction + (current_direction - 1);
  }
}

void Housekeeping(int which_case)
{
  if (which_case<2)
  { // enable/disable motor
    digitalWrite(enable_pin, bool(which_case));
  }
  else
  { // change stepsize
    stepsize = which_case; // stepsize can be set from 2-9
  }
}
