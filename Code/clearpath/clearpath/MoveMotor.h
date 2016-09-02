/* Standalone function to move clearpath motor
November 30, 2015
*/

#ifndef MoveMotor_h
#define MoveMotor_h

#include "Arduino.h"

class MoveMotor
{
	public:
		MoveMotor( int locations_per_zone, int enable_pin, int dir_pin, int step_pin, int home_pin);
		void ToHome();
		void ResetMotor(bool motor_on);
		void SwitchDir(bool motor_direction);
		bool Move(int motor_location[]);
	private:
		int _locations_per_zone;
		int _enable_pin;
		int _dir_pin;
		int _step_pin;
		int _home_pin;
		int _motor_location[];
		int _steps_to_move;
		int _i;
		int _steptime[];
		int _stepsize_in_targetzone;
		int _stepsize_outside_targetzone;
		int _stepsize[];
};

#endif
