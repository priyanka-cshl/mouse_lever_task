#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// motor control pins
const byte enable_pin = 23;
const byte dir_pin = 25;
const byte step_pin = 27;
const byte servoON_pin = 29;
const byte home_pin = 51;
const byte end_stop_pin_left = 2;
const byte end_stop_pin_right = 3;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
const byte home_out = 47;
bool motor_ON = false;
int home_location = 0;
bool cheat = false;

// motor position variables
int desired_location = 101;
int current_location = 101;
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
byte motor_positions[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
byte readpointer = 0;
byte writepointer = 0;
byte value_received = 0;

void setup ()
{
  // Initialize control pins
  pinMode(enable_pin, OUTPUT);
  digitalWrite(enable_pin, LOW);
  pinMode(dir_pin, OUTPUT);
  digitalWrite(dir_pin, HIGH); // set to CW
  pinMode(step_pin, OUTPUT);
  digitalWrite(step_pin, LOW);
  pinMode(home_out, OUTPUT);
  digitalWrite(home_out, LOW);
  pinMode(home_pin, INPUT_PULLUP);
  pinMode(servoON_pin, INPUT_PULLUP);
  
  // I2C setup
  Wire_received = 0; //edited
  readpointer = 0;
  writepointer = 0;
  Wire.begin(7); // join I2C bus with address/ 7 (Motor1)
  //Wire.begin(8); // join I2C bus with address 7 (Motor2)
  Wire.onReceive(receiveEvent);

  // safety switches (end-stops)
  //disable motor when it reaches an end stop
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, FALLING);
  // debugging
  Serial.begin (115200);
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

void SafetyStopLeft()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  FindHome(true);
}

void SafetyStopRight()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  FindHome(false);
}

void FindHome(bool which_direction)
{
  busy = 1;
  digitalWrite(enable_pin, false);

  // set direction accordingly
  digitalWrite(dir_pin, which_direction);
  current_direction = (int)which_direction;
  delay(500);
  
  // enable motor again
  digitalWrite(enable_pin, true);

  if (digitalRead(home_pin)) 
  {
    // if home pin is already blocked
    // reverse direction and take 80 steps 
    digitalWrite(dir_pin, !which_direction);
    delay(5000);
    for (int h = 0; h < 100; h++)
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delay(1000);
    }
    digitalWrite(dir_pin, which_direction);
    delay(500);
  }
  
  // move until it reaches home OR hits the other switch
  //while (!digitalRead(home_pin) && digitalRead(end_stop_pin_left + (int)which_direction))
  while (!digitalRead(home_pin) && digitalRead(end_stop_pin_left+ (int)which_direction)) //&& digitalRead(end_stop_pin_right))
  {
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
    delay(1000);
  }

  // if the other switch was hit, give up
  //if (!digitalRead(end_stop_pin_left + (int)which_direction))
  if (!digitalRead(end_stop_pin_left) || !digitalRead(end_stop_pin_right))
  {
    digitalWrite(enable_pin, false); // turn OFF motor
    busy = 0;
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
  }
  else
  {
    home_location = 0;

    // advance 1 more step to ensure that the switch is blocked
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
    home_location = home_location + 1;
    delay(1000);

    // find #steps needed to unblock photoswitch
    while (digitalRead(home_pin))
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      home_location = home_location + 1;
      delay(1000);
    }

    //reverse direction
    digitalWrite(dir_pin, !which_direction);
    current_direction = (int)!which_direction;
    delay(5000);
    
    // actual home location is midway
    for (int h = home_location; h >= (home_location / 2); h--)
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delay(1000);
    }

    // send AtHome signal to the rotary encoder Arduino
    digitalWrite(home_out, HIGH);
    delay(1000);
    digitalWrite(home_out, LOW);
    delay(1000);

    // update location and release motor for directed movements
    
    current_location = 101;
    desired_location = 101;
    // overwite all values in buffer to home location
    for (int h = 0; h < 10; h++)
    {
       motor_positions[h] = 101 + 10; 
    }
    digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
    busy = 0;
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
    //interrupts();
  }
}

void loop ()
{
  Serial.println(digitalRead(home_pin));
  if (Wire_received > 0) //edited
  {
    value_received = motor_positions[readpointer];
    //Serial.println(value_received);
    if (value_received >= 10)
    {
      desired_location = value_received - 10;
      delta_steps = stepsize * abs(desired_location - current_location);
      if ( delta_steps <= 50 )
      {
        step_wait = round(5000 / delta_steps);
      }
      else
      {
        step_wait = round(8000 / delta_steps);
      }
//      Serial.print(current_location);
//      Serial.print(" ");
//      Serial.println(desired_location);
    }
    else
    {
      //Serial.println(value_received);
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
    for (i = 0; i < stepsize; i++)
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delayMicroseconds(step_wait);
    }
    // hack to increment current location: +1 if direction CW, -1 otherwise
    current_location = current_location + current_direction + (current_direction - 1);
  }
}

void Housekeeping(int which_case)
{
  if (which_case < 2)
  {
    digitalWrite(enable_pin, bool(which_case));
    motor_ON = bool(which_case);
  }
  else if (which_case < 3)
  { // Home the motor by finding home
     MyCheatHome();
  }
  else
  { // change stepsize, range = 2-9
    stepsize = which_case - 2;
  }
}

void MyCheatHome()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  // turn motor ON if its off
  if (!motor_ON)
  {
    digitalWrite(enable_pin, 1);
    motor_ON = true;
  }
  // move motor until it hits one of the home switches and can fire an interrupt
  while ((digitalRead(end_stop_pin_left)) && (digitalRead(end_stop_pin_right)))
  {    
    delay(10);
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
  }
  if (digitalRead(end_stop_pin_left))
  {
    FindHome(true);
  }
  else
  {
    FindHome(false);
  }
}

