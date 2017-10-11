/* Standalone function to evaluate the current trialstate
  November 27, 2015
*/

#include "Arduino.h"
#include "trialstates.h"

trialstates::trialstates()
{
}

void trialstates::UpdateTrialParams(long trigger_limits[], int trigger_time[])
{
  _trial_trigger_on = trigger_limits[0];
  _trial_trigger_off = trigger_limits[1];
  _min_trigger_on_duration = 1000 * trigger_time[0];
  _trigger_smooth = 1000 * trigger_time[1];
  _min_trial_duration = 1000 * trigger_time[2];
  _max_trial_duration = 1000 * trigger_time[3];
}

void trialstates::UpdateITI(int long_iti)
{
  _iti = 1000 * long_iti;
}

int trialstates::WhichState(int trialstate, long lever_position, long time_since_last_change)
{
  // parse values from public variables to private variables
  _trialstate = trialstate;
  _lever_position = lever_position;
  _time_since_last_change = time_since_last_change;

  switch (_trialstate)
  {
    case 0: // pre-trial state
      if ( (_lever_position > _trial_trigger_on)
        & _time_since_last_change > _iti )
      {
        _trialstate = 1;
      }
      break;
    case 1: // going to 'activate trial trigger state' state
      if (_lever_position <= _trial_trigger_on)
      {
        _trialstate = 0; // failed attempt : go back to pre-trial
      }
      else if ( _time_since_last_change >= _min_trigger_on_duration )
      { // above trial triggerON theshold long enough - activate trial
        _trialstate = 2;
      }
      break;
    case 2: // odor/air is on, start trial clock but reset it, if a movement is initiated
      if ( (_lever_position < _trial_trigger_on)
           & _time_since_last_change < _max_trial_duration )
      {
        _trialstate = 4;
      }
      if ( _time_since_last_change > _max_trial_duration )
      {
        _trialstate = 0;
      }
      break;
    case 4: // in active trial mode
      // if time elapsed is less than _min_trial_duration
      // and lever is beyond lower limit - terminate trial
      if ( (_lever_position < _trial_trigger_off)
           & _time_since_last_change < _min_trial_duration )
      {
        _trialstate = 0;
      }
      // if time elapsed is more than _max_trial_duration
      // terminate trial
      if ( _time_since_last_change > _max_trial_duration )
      {
        _trialstate = 0;
      }
      break;
  }
  return _trialstate;
}

