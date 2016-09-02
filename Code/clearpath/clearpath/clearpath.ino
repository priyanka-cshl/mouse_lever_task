#include "MoveMotor.h" 
// function to move clearpath motorint enable_pint = 7;
 
int enable_pint = 7;
int dir_pint = 8;
int step_pint = 23;
int i = 0;

int motor_locations_per_zone = 16; // motor positions per zone
MoveMotor MotorOne(motor_locations_per_zone,7,8,23,10);

//pins
int lever_in = A0;

//variables : lever related
long lever_position = 0L;
int motor_position[] = {0, 0};
bool motor_direction[] = {0, 0};
int totalsteps = 200;
int dir_wait = 30; // in microseconds
int step_wait[] = {10, 10}; // in microseconds
int steps_to_move = 0;

bool direct = 1;
bool use_library = 1;

int stimulus_state[] = {0, 0}; // old, new
long stimulus_state_timestamp = micros();
const int min_time_since_last_stimulus_state = 100000; // in microseconds
int stimulus_state_array[255][2] = {{0},{0}};
int direction_state_array[255] = {0};
unsigned long stimulus_state_timestamp_array[255] = {micros()};
int stimulus_writepointer = 0;
int stimulus_readpointer = 0;
int delay_feedback_by = 100; // in milliseconds 


void setup() 
{
  // put your setup code here, to run once:
  analogReadResolution(12);
  Serial.begin(115200); 
  if (!use_library)
  {
  pinMode(dir_pint,OUTPUT);
  pinMode(step_pint,OUTPUT);
  pinMode(enable_pint,OUTPUT);

  // enable motor and set direction to CW
  digitalWrite(enable_pint,HIGH);
  digitalWrite(dir_pint,HIGH);
  }
  else
  {
  MotorOne.SwitchDir(1);
  }
  motor_direction[0] = 1;

  // initialize arrays
  for (i = 0; i < 256; i++)
  {
    stimulus_state_array[i][0] = -1;
    stimulus_state_array[i][1] = -1;
    direction_state_array[i] = 0;
    stimulus_state_timestamp_array[i] = 0;
  }

  if (use_library)
  {
    totalsteps = 64;
  }
}


void loop() 
{   
  //----------------------------------------------------------------------------
  // 1) process the incoming lever position data
  //----------------------------------------------------------------------------
  // read lever position as analog val 
  lever_position = analogRead(lever_in);
  // remap from 12-bit to 16-bit 
  lever_position = map(lever_position, 0, 4095, 0, 65534);
  motor_position[1] = map(lever_position, 0, 65534, 0, totalsteps);
  Serial.print(lever_position);
  Serial.print(' ');
  Serial.print(totalsteps);
  Serial.print(' ');
  Serial.println(motor_position[1]);
  
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 2) move the motor
  // how much to move?
  if (motor_position[1] != motor_position[0])
  {
    stimulus_state_timestamp = micros();
    stimulus_state_timestamp_array[stimulus_writepointer] = stimulus_state_timestamp;
    direction_state_array[stimulus_writepointer] = 0;
    motor_direction[1] = (motor_position[1] > motor_position[0]);
    // change direction if needed
    if (motor_direction[1] != motor_direction[0])
    {
      motor_direction[0] = motor_direction[1];
      if (direct)
      {
        if (use_library)
        {
          Serial.println(motor_position[1]);
          //MotorOne.SwitchDir((bool)motor_direction[1]);
        }
        else
        {
          motor_dir((bool)motor_direction[1]);
        }
        
      }
      else
      {
        direction_state_array[stimulus_writepointer] = motor_direction[1] + 1;
        stimulus_writepointer = (stimulus_writepointer + 1) % 255; 
      }
    }
    // update position
    steps_to_move = abs(motor_position[1] - motor_position[0]);
    if (direct)
    {
      if (use_library)
      {
        //MotorOne.Move(motor_position);
      }
      else 
      {
        motor_move(steps_to_move);
      }
    }
    else
    {
      stimulus_state_array[stimulus_writepointer][0] = motor_position[0];
      stimulus_state_array[stimulus_writepointer][1] = motor_position[1];
    }
    motor_position[0] = motor_position[1];
  }
  //----------------------------------------------------------------------------

//  if (!direct)
//  {
//    if ((micros() - stimulus_state_timestamp_array[stimulus_readpointer] > 1000*delay_feedback_by)
//    && (stimulus_state_array[stimulus_readpointer][1] != -1) )
//    {
//      if (direction_state_array[stimulus_readpointer] > 0)
//      {
//        Serial.println(direction_state_array[stimulus_readpointer]);
//        motor_dir((bool)(direction_state_array[stimulus_readpointer]-1));
//      }
//      steps_to_move = abs(stimulus_state_array[stimulus_readpointer][1] -stimulus_state_array[stimulus_readpointer][0]);
//      motor_move(steps_to_move);
//      stimulus_state_array[stimulus_readpointer][1] = -1;
//      stimulus_readpointer = (stimulus_readpointer + 1) % 255; 
//    }
//  }
}

void motor_dir(bool dir_now)
{
      digitalWrite(dir_pint,dir_now);
      delayMicroseconds(dir_wait);
}

void motor_move(int steps)
{
    for (i = 0; i < steps; i++)
    {
      digitalWrite(step_pint,HIGH);
      delayMicroseconds(step_wait[0]);
      digitalWrite(step_pint,LOW);
      delayMicroseconds(step_wait[1]);
    }
}
