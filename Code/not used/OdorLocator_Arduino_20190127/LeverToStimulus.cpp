/* Standalone function to map lever location to stimulus
  November 28, 2015
*/

#include "Arduino.h"
#include "LeverToStimulus.h"

LeverToStimulus::LeverToStimulus()
{
}

void LeverToStimulus::UpdateTargetParams(int target_settings[], int fake_target_settings[], int trial_off_bound)
{
  _target_upper_bound = target_settings[0];
  _target = target_settings[1];
  _target_lower_bound = target_settings[2];
  _fake_target_upper_bound = fake_target_settings[0];
  _fake_target = fake_target_settings[1];
  _fake_target_lower_bound = fake_target_settings[2];
  _trial_off_bound = trial_off_bound;
}

void LeverToStimulus::UpdateLocations(int target_limits[])
{
    _limit_1 = target_limits[0];
    _limit_2 = target_limits[1];
    _limit_3 = target_limits[2];
    _limit_4 = target_limits[3];
    _limit_5 = target_limits[4];
    _limit_6 = target_limits[5];
}

int LeverToStimulus::WhichZone(int stimulus_case, long lever_position)
{
  // parse values from public variables to private variables
  _stimulus_case = stimulus_case;
  _lever_position = lever_position;

  // update target settings basrd on stimulus case - real or fake
  switch (_stimulus_case)
  {
    case 1: // actual target
      _target_high = _target_upper_bound;
      _target_low = _target_lower_bound;
      _target_val = _target;
      break;
    case 2: // fake target
      _target_high = _fake_target_upper_bound;
      _target_low = _fake_target_lower_bound;
      _target_val = _fake_target;
      break;
  }

  // compute stimulus location based on lever's current position and target settings
  if (_lever_position <= _trial_off_bound)
  { // ignore values below a fixed threshold
    _stimulus_location = 0;
  }
  // in active trial and above threshold
  else if (_lever_position == constrain(_lever_position, _target_low, _target_high))
  { // in the target zone
    _relative_position = abs(_lever_position - _target_val);
    _lever_range = _target_high - _target_low;
    _stimulus_location = map(_relative_position, 0, _lever_range, _limit_3, _limit_4);
  }
  else if (_lever_position < _target_low)
  { // in the left zone : zone 1
    _relative_position = abs(_lever_position - 1311);
    _lever_range = _target_low - 1311;
    _stimulus_location = map(_relative_position, 0, _lever_range, _limit_1, _limit_2);
  }
  else
  { // in the right zone : zone 4
    _relative_position = 65535 - _lever_position;
    _lever_range = 65535 - _target_high;
    _stimulus_location = map(_relative_position, 0, _lever_range, _limit_6, _limit_5);
  }
  
  return _stimulus_location;
}
