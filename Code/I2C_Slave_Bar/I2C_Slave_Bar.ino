#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// motor control pins
const byte home_pin = 51;
const byte end_stop_pin_left = 2; //right of mouse
const byte end_stop_pin_right = 3;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
const byte home_out = 47;
bool motor_ON = false;
byte home_location = 121;
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
  //attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
  //attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, FALLING);
  // debugging
 Serial.begin(9600);
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
  busy = 1;
  // first check if its already homed
  if (digitalRead(home_pin))
  {
    //digitalWrite(enable_pin, false);

    // set direction accordingly
    //digitalWrite(dir_pin, which_direction);
    current_direction = (int)which_direction;
    delay(500);

    // enable motor again
    //digitalWrite(enable_pin, true);

    // move until it reaches home OR hits the other switch
    //while (!digitalRead(home_pin) && digitalRead(end_stop_pin_left + (int)which_direction))
    while (digitalRead(home_pin) && digitalRead(end_stop_pin_left + (int)which_direction)) //&& digitalRead(end_stop_pin_right))
    {
      //digitalWrite(step_pin, HIGH);
      //digitalWrite(step_pin, LOW);
      delay(1000);
    }

    // if the other switch was hit, give up
    if (!digitalRead(end_stop_pin_left) || !digitalRead(end_stop_pin_right))
    {
      //digitalWrite(enable_pin, false); // turn OFF motor
      busy = 0;
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
    }
    else
    {
      // send AtHome signal to the rotary encoder Arduino
      digitalWrite(home_out, HIGH);
      delay(1000);
      digitalWrite(home_out, LOW);
      delay(1000);

      // update location and release motor for directed movements
      current_location = home_location;
      desired_location = home_location;
      motor_positions = home_location + 10;
      //digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
      busy = 0;
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
      //interrupts();
    }
  }
  else
  {
    // send AtHome signal to the rotary encoder Arduino
      digitalWrite(home_out, HIGH);
      delay(100);
      digitalWrite(home_out, LOW);
      delay(100);

      // update location and release motor for directed movements
      current_location = home_location;
      desired_location = home_location;
      motor_positions = home_location + 10;
      //digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
      busy = 0;
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
      //interrupts();
  }
}

void loop ()
{
  Serial.println(motor_positions);
  if (Wire_received > 0) //edited
  {
    //value_received = motor_positions[readpointer];
    value_received = motor_positions;
    //Serial.println(value_received);
    if (value_received >= 10)
    {
      desired_location = value_received - 10;
      current_location = desired_location;
    }
    else
    {
      Housekeeping(value_received);
    }
    //readpointer = (readpointer + 1) % 10;
    Wire_received = Wire_received - 1; //edited
  }
}

void Housekeeping(int which_case)
{
  if (which_case < 2)
  {
    //digitalWrite(enable_pin, bool(which_case));
    motor_ON = bool(which_case);
  }
  else if (which_case < 3)
  { // Home the motor by finding home
    MyCheatHome();
  }
  else
  { // change stepsize, range = 1-5
    stepsize = which_case - 2;
  }
}

void MyCheatHome()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  // turn motor ON if its off

  // move motor until it hits one of the home switches and can fire an interrupt
  while ((digitalRead(end_stop_pin_left)) && (digitalRead(end_stop_pin_right)) && digitalRead(home_pin))
  {
    delay(10);
//    digitalWrite(step_pin, HIGH);
//    digitalWrite(step_pin, LOW);
  }
  if (!digitalRead(home_pin))
  {
    // send AtHome signal to the rotary encoder Arduino
      digitalWrite(home_out, HIGH);
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
