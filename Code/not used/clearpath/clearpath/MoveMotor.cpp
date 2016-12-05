/* Standalone function to move clearpath motor
November 30, 2015
*/

#include "Arduino.h"
#include "MoveMotor.h"

MoveMotor::MoveMotor(int locations_per_zone, int enable_pin, int dir_pin, int step_pin, int home_pin)
{
	// pass over variables
	_locations_per_zone = locations_per_zone;
	_enable_pin = enable_pin;
	_dir_pin = dir_pin;
	_step_pin = step_pin;
	_home_pin = home_pin;
	

  // setup all control pins
  pinMode(_enable_pin,OUTPUT);
  pinMode(_dir_pin,OUTPUT);
  pinMode(_step_pin,OUTPUT);
  pinMode(_home_pin,INPUT);
  
  // set initial direction to CW
  digitalWrite(_enable_pin, HIGH);
  delay(10);
  digitalWrite(_dir_pin, HIGH);
  
	//int _motor_location[] ={0, 0};
	//int _steps_to_move;
	_i = 0;
	
	// MOTOR SETTINGS
	int _steptime[] = {10, 10, 20}; // in microseconds 
	_stepsize_in_targetzone = 2;
	_stepsize_outside_targetzone = 2;
	//int _stepsize[] = {};
	
	// set up motor locations in terms of steps
	_stepsize[0] = _stepsize_outside_targetzone;
	for (_i = 1; _i <= _locations_per_zone; _i++)
	{
		_stepsize[_i] = _stepsize_outside_targetzone;
	}
	for (_i = 17; _i <= 3*_locations_per_zone; _i++)
	{
		_stepsize[_i] = _stepsize_in_targetzone;
	}
	for (_i = 49; _i <= 4*_locations_per_zone; _i++)
	{
		_stepsize[_i] = _stepsize_outside_targetzone;
	}
}

void MoveMotor::ToHome()
{
	// make sure motor is enabled
	digitalWrite(_enable_pin, HIGH);
	delay(10);
	// set direction to clockwise
	digitalWrite(_dir_pin, HIGH);
	delay(25);
	// start moving the motor, one step at a time till it hits home
	while (!digitalRead(_home_pin))
	{
		digitalWrite(_step_pin,HIGH);
		delayMicroseconds(_steptime[0]);
		digitalWrite(_step_pin,LOW);
		delayMicroseconds(_steptime[1]);		
	}
}

void MoveMotor::ResetMotor(bool motor_on)
{
	if (motor_on)
	{
		digitalWrite(_enable_pin, HIGH);
		delay(10);
		digitalWrite(_dir_pin, HIGH);
	}
	else
	{
		digitalWrite(_enable_pin, LOW);
	}
 
}

void MoveMotor::SwitchDir(bool motor_direction)
{
	digitalWrite(_dir_pin, motor_direction);
  delayMicroseconds(_steptime[2]);    
  
}

bool MoveMotor::Move(int motor_location[])
{
  //parse values from public variables to private variables
	_steps_to_move = 0;
	if (motor_location[1]>motor_location[0])
	{
		_motor_location[0] = motor_location[0];
                _motor_location[1] = motor_location[1];
	}
	else
	{
		_motor_location[0] = motor_location[1];
		_motor_location[1] = motor_location[0];
	}

        for (_i = _motor_location[0]; _i < _motor_location[1]; _i++)
        {
          _steps_to_move = _steps_to_move + _stepsize[_i];
        }
	// move the motor
	for (_i = 0; _i < _steps_to_move; _i++)
	{
		digitalWrite(_step_pin,HIGH);
		delayMicroseconds(_steptime[0]);
		digitalWrite(_step_pin,LOW);
		delayMicroseconds(_steptime[1]);
	}        

  return false; // flag for IsMotorMoving?
}

