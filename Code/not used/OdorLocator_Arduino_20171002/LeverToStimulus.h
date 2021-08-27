/* Standalone function to map lever location to stimulus
November 28, 2015
*/

#ifndef LeverToStimulus_h
#define LeverToStimulus_h

#include "Arduino.h"

class LeverToStimulus
{
	public:
		LeverToStimulus();
	  	void UpdateTargetParams(int target_settings[], int fake_target_settings[], int trial_off_bound);
	  	void UpdateLocations(int target_limits[]);
	  	int WhichZone(int stimulus_case, long lever_position);
	private:
		long _target_upper_bound;
		long _target_lower_bound; 
		long _target;
		long _fake_target_upper_bound; 
		long _fake_target_lower_bound;
		long _fake_target;
    long _trial_off_bound;
		long _target_high;
		long _target_low; 
		long _target_val;
		int _stimulus_case;
		long _lever_position;
		long _relative_position;
		long _lever_range;
		int _stimulus_location;
    int _limit_1;
    int _limit_2;
    int _limit_3;
    int _limit_4;
    int _limit_5;
    int _limit_6;
};

#endif

