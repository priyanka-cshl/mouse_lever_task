#include <Wire.h> // for I2C communication with Master Arduino

// general
int i = 0;

// motor control pins
const byte enable_pin = 7;
const byte dir_pin = 6;
const byte step_pin = 5;
const byte servoON_pin = 4; //HFLB
const byte home_pin = 51;
const byte end_stop_pin_left = 2;
const byte end_stop_pin_right = 3;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
const byte home_out = 47;
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

// I2C variables
volatile int Wire_received = 0; //edited
byte motor_positions = 0;
byte readpointer = 0;
byte writepointer = 0;
byte value_received = 0;

void setup() {
  // put your setup code here, to run once:
  pinMode(enable_pin, OUTPUT);
  digitalWrite(enable_pin, LOW);
  pinMode(dir_pin, OUTPUT);
  digitalWrite(dir_pin, HIGH); // set to CW
  pinMode(step_pin, OUTPUT);
  digitalWrite(step_pin, LOW);
  pinMode(servoON_pin, INPUT_PULLUP);
  pinMode(home_pin, INPUT_PULLUP);
  pinMode(home_out, OUTPUT);
  digitalWrite(home_out, LOW);
  
  pinMode(end_stop_pin_left, INPUT_PULLUP);
  pinMode(end_stop_pin_right, INPUT_PULLUP);
  

    // I2C setup
  Wire_received = 0; //edited
  readpointer = 0;
  writepointer = 0;
//  Wire.begin(7); // join I2C bus with address/ 7 (Motor1)
//  //Wire.begin(8); // join I2C bus with address 7 (Motor2)
//  Wire.onReceive(receiveEvent);

  

  attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
  attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, FALLING);
  
  Serial.begin (115200);
}

void SafetyStopLeft()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  FindHome(false);
}

void SafetyStopRight()
{
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_right));
  detachInterrupt(digitalPinToInterrupt(end_stop_pin_left));
  FindHome(true);
}

void FindHome(bool which_direction)
{
  busy = 1;
  // first check if its already homed
  if (digitalRead(home_pin)) // home is low when the motor is homed for rig2
  {
    digitalWrite(enable_pin, false);

    // set direction accordingly
    digitalWrite(dir_pin, which_direction);
    current_direction = (int)which_direction;
    delay(500);

    // enable motor again
    digitalWrite(enable_pin, true);

    // move until it reaches home OR hits the other switch
    //while (!digitalRead(home_pin) && digitalRead(end_stop_pin_left + (int)which_direction))
    while (digitalRead(home_pin) && digitalRead(end_stop_pin_right - (int)which_direction)) //&& digitalRead(end_stop_pin_right))
    {
      digitalWrite(step_pin, HIGH);
      digitalWrite(step_pin, LOW);
      delay(1000);
    }

    // if the other switch was hit, give up
    if (!digitalRead(end_stop_pin_left) || !digitalRead(end_stop_pin_right))
    {
      digitalWrite(enable_pin, false); // turn OFF motor
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
      digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
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
      digitalWrite(enable_pin, motor_ON); // turn On if motor was ON before
      busy = 0;
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStopLeft, LOW);
      attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStopRight, LOW);
      //interrupts();
  }
}

void loop() {
  // put your main code here, to run repeatedly:
  //Serial.println(digitalRead(end_stop_pin_right));
  //Serial.println(digitalRead(end_stop_pin_left));
  //Serial.println(digitalRead(home_pin));
}
