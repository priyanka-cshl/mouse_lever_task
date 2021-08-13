/* Standalone function to evaluate the current trialstate
  November 27, 2015
*/

#include "Arduino.h"
#include "openlooptrialstates.h"

openlooptrialstates::openlooptrialstates()
{
}

void openlooptrialstates::UpdateOpenLoopTrialParams(int trial_time[])
{
  _motor_settle_duration = 1000 * trial_time[0];
  _pre_odor_duration = 1000 * trial_time[1];
  _odor_duration = 1000 * trial_time[2];
  _purge_duration = 1000 * trial_time[3];
  _post_odor_duration = 1000 * trial_time[4]; 
  _iti_duration = 1000 * trial_time[5];
}

int openlooptrialstates::WhichState(int openlooptrialstate, long time_since_last_change)
{
  // parse values from public variables to private variables
  _openlooptrialstate = openlooptrialstate;
  _time_since_last_change = time_since_last_change;

  switch (_openlooptrialstate)
  {
    case 0: // motor_settle phase
      if (_time_since_last_change >= _motor_settle_duration)  
      {
        _openlooptrialstate = 1; // start clean air, turn on air flow
      }
      break;
    case 1: // deliver clean air
      if (_time_since_last_change >= _pre_odor_duration)
      {
        _openlooptrialstate = 4; // switch to odor
      }
      break;
    case 4: // deliver odor
      if (_time_since_last_change >= _odor_duration)
      {
        if (_purge_duration>0)
        {
          _openlooptrialstate = 2; // switch to air again
        }
        else
        {
          _openlooptrialstate = 3; // switch to no flow directly
        }
      }
      break;
    case 2: // purge with air
      if (_time_since_last_change >= _purge_duration)
      {
        _openlooptrialstate = 3; // change to no flow
      }
      break;
    case 3: // deliver clean air - II
      if (_time_since_last_change >= _post_odor_duration)
      {
        _openlooptrialstate = 5; // turn off flow, wait in ITI
      }
      break;  
    case 5: // ITI
      if (_time_since_last_change >= _iti_duration)
      {
        _openlooptrialstate = 0; // move motor to next location
      }
      break;    
  }
  return _openlooptrialstate;
}
