/* Standalone function to evaluate the current trialstate
  November 27, 2015
*/

#include "Arduino.h"
#include "sequencetrialstates.h"

sequencetrialstates::sequencetrialstates()
{
}

void sequencetrialstates::UpdateSequenceTrialParams(int trial_time[])
{
  _pre_odor_duration = 1000 * trial_time[0];
  _odor_duration = 1000 * trial_time[1];
  _post_odor_duration = 1000 * trial_time[2]; 
  _iti_duration = 1000 * trial_time[3];
}

int sequencetrialstates::WhichState(int sequencetrialstate, long time_since_last_change, int stimcount)
{
  // parse values from public variables to private variables
  _sequencetrialstate = sequencetrialstate;
  _time_since_last_change = time_since_last_change;
  _stimcount = stimcount;

  switch (_sequencetrialstate)
  {
    case 0: // motor_settle phase
      if (_time_since_last_change >= 1000*100)  
      {
        _sequencetrialstate = 1; // start clean air, turn on air flow
      }
      break;
    case 1: // deliver clean air
      if (_time_since_last_change >= _pre_odor_duration)
      {
        _sequencetrialstate = 4; // switch to odor
      }
      break;
    case 4: // deliver odor
      if (_time_since_last_change >= _odor_duration)
      {
        if (_stimcount<5)
        {
          _sequencetrialstate = 2; // switch to air again - in-between odors
        }
        else
        {
          _sequencetrialstate = 3; // switch to post-odor
        }
      }
      break;
    case 2: // purge with air
      if (_time_since_last_change >= _post_odor_duration)
      {
        _sequencetrialstate = 4; // change to odor again
      }
      break;
    case 3: // deliver clean air - II
      if (_time_since_last_change >= _post_odor_duration)
      {
        _sequencetrialstate = 5; // turn off flow, wait in ITI
      }
      break;  
    case 5: // ITI
      if (_time_since_last_change >= _iti_duration)
      {
        _sequencetrialstate = 0; // move motor to next location
      }
      break;    
  }
  return _sequencetrialstate;
}
