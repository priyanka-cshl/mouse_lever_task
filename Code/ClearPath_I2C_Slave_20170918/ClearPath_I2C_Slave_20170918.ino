#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// OUTPUTS 
const byte enable_pin = 23; // clearpath motor control pins
const byte dir_pin = 25;
const byte step_pin = 27;
const byte servoON_pin = 31; //HFLB
const byte SDA_pin = 20; // I2C communication
const byte SCL_pin = 21;
const byte home_out = 47; // 
// INPUTS - sensors and stops
const byte home_pin = 51;
const byte end_stop_pin_left = 2;
const byte end_stop_pin_right = 3;


bool motor_ON = false;
int home_location = 101;
int max_location = 200;
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
  for (int j = 0; j < howmany; j++)
  {
    byte c = Wire.read();
    motor_positions = c;
  }
  Wire_received = Wire_received + 1; //edited
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
  busy = 1; // disable other move commands
  if (!digitalRead(home_pin)) // check if its not already homed
  {
    digitalWrite(enable_pin, false); // turn off Motor - to prevent jamming it against the stop switch
    digitalWrite(dir_pin, which_direction); // set direction accordingly
    current_direction = (int)which_direction;
    delay(500);
    digitalWrite(enable_pin, true); // enable motor again

    // move until it reaches home OR hits the other switch
    while (!digitalRead(home_pin) && digitalRead(end_stop_pin_left + (int)which_direction))
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delay(1000);
    }

    // if the other switch was hit, give up
    if (!digitalRead(end_stop_pin_left) || !digitalRead(end_stop_pin_right))
    {
      digitalWrite(enable_pin, false); // turn OFF motor
    }
    else
    {
      digitalWrite(home_out, HIGH); // send AtHome signal to the rotary encoder Arduino
      delay(1000);
      digitalWrite(home_out, LOW);
      delay(1000);
      // update location and release motor for directed movements
      current_location = home_location;
      desired_location = home_location;
      motor_positions = home_location + 10;
      digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
    }
  }
  else // was already homed
  {
    digitalWrite(home_out, HIGH); // send AtHome signal to the rotary encoder Arduino
    delay(100);
    digitalWrite(home_out, LOW);
    delay(100);
    // update location and release motor for directed movements
    current_location = home_location;
    desired_location = home_location;
    motor_positions = home_location + 10;
    digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
  }
  busy = 0;
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
}

void loop()
{
  //Serial.println(motor_positions);
  if (Wire_received > 0)
  {
    value_received = motor_positions;
    //Serial.println(value_received);
    if (value_received >= 10)
    {
      desired_location = value_received - 10;
      delta_steps = stepsize * abs(desired_location - current_location);
      if (delta_steps <= 50)
      {
        step_wait = round(4000 / delta_steps);
      }
      else
      {
        step_wait = round(6000 / delta_steps);
      }
    }
    else
    {
      Housekeeping(value_received);
    }
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
  else if (which_case < 5)
  {
    MoveToStart(which_case - 3); // send 0 or 1
  }
  else
  { // change stepsize, range = 1-5
    stepsize = which_case - 4;
  }
}

void MyCheatHome()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  if (!motor_ON) // turn motor ON if its off
  {
    digitalWrite(enable_pin, 1);
    motor_ON = true;
  }
  // move motor until it hits one of the home switches and can fire an interrupt
  while ((digitalRead(end_stop_pin_left)) && (digitalRead(end_stop_pin_right)) && !digitalRead(home_pin))
  {
    delay(10);
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
  }
  if (digitalRead(home_pin))
  {
    digitalWrite(home_out, HIGH); // send AtHome signal to the rotary encoder Arduino
    delay(1000);
    digitalWrite(home_out, LOW);
    delay(1000);
    // update location and release motor for directed movements
    current_location = home_location;
    desired_location = home_location;
    motor_positions = home_location + 10;
  }
  else if (digitalRead(end_stop_pin_left))
  {
    FindHome(true);
  }
  else
  {
    FindHome(false);
  }
}

void MoveToStart(int which_case)
{
  busy = 1; // disable other move commands
  desired_location = which_case*max_location;
  if (current_location != desired_location)
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
      delayMicroseconds(1000);
    }
    // hack to increment current location: +1 if direction CW, -1 otherwise
    current_location = current_location + current_direction + (current_direction - 1);
  }
  current_location = desired_location;
  desired_location = desired_location;
  motor_positions = desired_location + 10;
  busy = 0;
}

