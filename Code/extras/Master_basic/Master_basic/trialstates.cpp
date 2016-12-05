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

int trialstates::WhichState(int trialstate, long lever_position, long time_since_last_change)
{
  // parse values from public variables to private variables
  _trialstate = trialstate;
  _lever_position = lever_position;
  _time_since_last_change = time_since_last_change;

  switch (_trialstate)
  {
    case 0: // pre-trial state
      if (_lever_position > _trial_trigger_on)
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
      { // above trial triggerON theshold long enough - can activate trial trigger
        _trialstate = 2;
      }
      break;
    case 2: // trial trigger is now armed, waiting for border cross
      if (_lever_position < _trial_trigger_on )
      {
        _trialstate = 3;
      }
      break;
    case 3: // trial is triggered once trial trigger has been armed for
      // longer than 25 ms (to overcome noise around the border)
      if ( _lever_position < _trial_trigger_on &
           _time_since_last_change > _trigger_smooth )
      {
        _trialstate = 4;
      }
      break;
    case 4: // in active trial mode
      // don't allow a change of state to pre-trial, if min_trial_duration has not elapsed
      if ( (_lever_position != constrain(_lever_position, _trial_trigger_off, _trial_trigger_on))
           & _time_since_last_change > _min_trial_duration )
      {
        _trialstate = 0;
      }
      if ( (_lever_position == constrain(_lever_position, _trial_trigger_off, _trial_trigger_on))
                & _time_since_last_change > _max_trial_duration )
      {
        _trialstate = 0;
      }
      break;
      
  }
  return _trialstate;
}

