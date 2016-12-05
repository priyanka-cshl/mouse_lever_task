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
bool motor_ON = false;
int homing_location = 0;
byte k = 0;
volatile bool homing = false;
int test = 0;

// motor position variables
int home_location = 0;
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
  pinMode(home_pin, INPUT_PULLUP);
  //  pinMode(SDA_pin, INPUT_PULLUP);
  //  pinMode(SCL_pin, INPUT_PULLUP);
  pinMode(end_stop_pin_left, INPUT_PULLUP);
  pinMode(end_stop_pin_right, INPUT_PULLUP);

  // I2C setup
  Wire_received = 0; //edited
  readpointer = 0;
  writepointer = 0;
  Wire.begin(7); // join I2C bus with address/ 7 (Motor1)
  //Wire.begin(8); // join I2C bus with address 7 (Motor2)
  Wire.onReceive(receiveEvent);

  // safety switches (end-stops)
  //disable motor when it reaches an end stop
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStop, RISING);
  //attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, FALLING);
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

void SafetyStop()
{
  //Serial.println(100);
  if (!homing)
  { 
    busy = true;
    digitalWrite(enable_pin, false);
    test = test + 1;
    FindHome(1);
  }
}

void FindHome(int which_direction)
{
  homing = true;
  // set direction accordingly
  digitalWrite(dir_pin, (bool)which_direction);
  delay(5000);

  // enable motor again
  digitalWrite(enable_pin, true);
  // move until it reaches home
  
  while (!digitalRead(home_pin))
  {
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
    delay(10000);
    Serial.println(test);
  }

  // near home from one side
  homing_location = 0;

  // take 10 steps forward
  for (int h = 0; h < 10; h++)
  {
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
    delay(1000);
    homing_location = homing_location + 1;
  }

  //Serial.println(digitalRead(home_pin));

  while (digitalRead(home_pin) == 1)
  {
    digitalWrite(step_pin, HIGH);
    digitalWrite(step_pin, LOW);
    //Serial.println(digitalRead(home_pin));
    //Serial.println(digitalRead(end_stop_pin_left));
    homing_location = homing_location + 1;
    delay(30000);
  }
  //Serial.println(digitalRead(end_stop_pin_left));

  //reverse direction
  digitalWrite(dir_pin, (bool)!current_direction);
  delay(30000);
  

  // update location and release motor for directed movements
  current_location = 101;
  digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
  busy = false;
  //homing = false;
}

void SafetyStopRight()
{
  //  busy = 1;
  //  digitalWrite(enable_pin, false);
  //
  //  // set direction accordingly
  //  current_direction = 0;
  //  digitalWrite(dir_pin, (bool)current_direction);
  //  delay(5000);
  //
  //  // enable motor again
  //  digitalWrite(enable_pin, true);
  //
  //  // move until it reaches home
  //  while (!digitalRead(home_pin))
  //  {
  //    digitalWrite(step_pin, HIGH);
  //    digitalWrite(step_pin, LOW);
  //    delay(1000);
  //  }
  //
  //  // near home from one side
  //  homing_location = 0;
  //  // take 10 more steps
  //  for (homing_location = 0; homing_location < 70; homing_location++)
  //  {
  //    digitalWrite(step_pin, HIGH);
  //    digitalWrite(step_pin, LOW);
  //    delay(1000);
  //  }
  //
  //  //reverse direction
  //  digitalWrite(dir_pin, (bool)!current_direction);
  //  delay(5000);
  //
  //  // move until it reaches home again
  //  while (!digitalRead(home_pin))
  //  {
  //    digitalWrite(step_pin, HIGH);
  //    digitalWrite(step_pin, LOW);
  //    delay(1000);
  //    homing_location = homing_location - 1;
  //  }
  //
  //  for (k = 0; k < homing_location/2; k++)
  //  {
  //    digitalWrite(step_pin, HIGH);
  //    digitalWrite(step_pin, LOW);
  //    delay(1000);
  //  }
  //
  //  // update location and release motor for directed movements
  //  current_location = 101;
  //  digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
  //  busy = 0;
}

void loop ()
{
  
  //  if (Wire_received > 0) //edited
  //  {
  //    value_received = motor_positions[readpointer];
  //    Serial.println(value_received);
  //    if (value_received >= 10)
  //    {
  //      desired_location = value_received - 10;
  //      delta_steps = stepsize * abs(desired_location - current_location);
  //      // calculate step time : max 10ms to make the move
  //      if ( delta_steps <= 50 )
  //      {
  //        step_wait = round(5000 / delta_steps);
  //      }
  //      else
  //      {
  //        step_wait = round(5000 / delta_steps);
  //      }
  //    }
  //    else
  //    {
  //      Housekeeping(value_received);
  //    }
  //    readpointer = (readpointer + 1) % 10;
  //    Wire_received = Wire_received - 1; //edited
  //  }
  //
  //  if ((current_location != desired_location) && !busy)
  //  {
  //    // check if the direction is correct, if not - switch direction
  //    if ((desired_location > current_location) != current_direction)
  //    {
  //      current_direction = !current_direction;
  //      digitalWrite(dir_pin, (bool)current_direction);
  //      delayMicroseconds(dir_wait);
  //    }
  //    // move now
  //    for (i = 0; i < stepsize; i++)
  //    {
  //      digitalWrite(step_pin, HIGH);
  //      digitalWrite(step_pin, LOW);
  //      delayMicroseconds(step_wait);
  //    }
  //    // hack to increment current location: +1 if direction CW, -1 otherwise
  //    current_location = current_location + current_direction + (current_direction - 1);
  //  }
}

void Housekeeping(int which_case)
{
  //  if (which_case < 2)
  //  {
  //    digitalWrite(enable_pin, bool(which_case));
  //    motor_ON = bool(which_case);
  //  }
  //  else
  //  { // change stepsize, range = 2-9
  //    stepsize = which_case - 1;
  //  }
}
