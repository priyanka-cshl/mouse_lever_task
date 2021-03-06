#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// motor control pins
const byte enable_pin = 23;
const byte dir_pin = 25;
const byte step_pin = 27;
const byte home_pin = 51;
const byte end_stop_pin_left = 2;
const byte end_stop_pin_right = 3;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
const byte home_out = 47;
bool motor_ON = false;
int home_location = 0;

// motor position variables
int desired_location = 0;
volatile int current_location = 101;
int delta_steps = 0;
volatile int current_direction = 1; // CW
int stepsize = 4; // motor location is between 1-50, steps allowed = 200 = quarter turn for the motor

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
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
  // debugging
  //Serial.begin (115200);
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
  if (!homing)
  {
    //noInterrupts();
    detachInterrupt(end_stop_pin_left);
    detachInterrupt(end_stop_pin_right);
    FindHome(true);
  }
}

void SafetyStopRight()
{
  if (!homing)
  {
    //noInterrupts();
    detachInterrupt(end_stop_pin_right);
    detachInterrupt(end_stop_pin_left);
    FindHome(false);
  }
}

void FindHome(bool which_direction)
{
  busy = 1;
  homing = 1;

  digitalWrite(enable_pin, false);

  // set direction accordingly
  digitalWrite(dir_pin, which_direction);
  delay(5000);

  // enable motor again
  digitalWrite(enable_pin, true);

  // move until it reaches home OR hits the other switch
  while (!digitalRead(home_pin) && digitalRead(end_stop_pin_left + (int)which_direction))
  {
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
    delay(1000);
  }

  // if the other switch was hit, give up
  if (!digitalRead(end_stop_pin_left + (int)which_direction))
  {
    digitalWrite(enable_pin, false); // turn OFF motor
    busy = 0;
    homing = 0;
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
  }
  else
  {
    home_location = 0;

    // advance 100 more steps (to cross over the photoswitch)
    for (int h = 0; h < 100; h++)
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      home_location = home_location + 1;
      delay(1000);
    }

    // reverse direction
    digitalWrite(dir_pin, !which_direction);
    delay(5000);

    // find home again
    while (!digitalRead(home_pin))
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      home_location = home_location - 1;
      delay(1000);
    }

    // actual home location is midway
    for (int h = 0; h < (home_location / 2); h++)
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delay(1000);
    }

    if (which_direction)
    {
      digitalWrite(dir_pin, which_direction);
      delay(5000);

      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delay(10000);
    }


    // send AtHome signal to the rotary encoder Arduino
    digitalWrite(home_out, HIGH);
    delay(1000);
    digitalWrite(home_out, LOW);
    delay(1000);

    // update location and release motor for directed movements
    current_location = 101;
    digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
    busy = 0;
    homing = 0;
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
    attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
    //interrupts();
  }
}

void loop ()
{
  if (Wire_received > 0) //edited
  {
    value_received = motor_positions[readpointer];
    //Serial.println(value_received);
    if (value_received >= 10)
    {
      desired_location = value_received - 10;
      delta_steps = stepsize * abs(desired_location - current_location);
      // calculate step time : max 10ms to make the move
      if ( delta_steps <= 50 )
      {
        step_wait = round(5000 / delta_steps);
      }
      else
      {
        step_wait = round(5000 / delta_steps);
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
  else
  { // change stepsize, range = 2-9
    stepsize = which_case - 1;
  }
}
