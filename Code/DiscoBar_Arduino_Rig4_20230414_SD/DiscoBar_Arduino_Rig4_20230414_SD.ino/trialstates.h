/* Standalone function to evaluate the current trialstate
  November 27, 2015
*/

#ifndef trialstates_h
#define trialstates_h

#include "Arduino.h"

class trialstates
{
  public:
    trialstates();
    void UpdateTrialParams(long trigger_limits[], int trigger_time[]);
    void UpdateITI(int long_iti);
    int WhichState(int trialstate, long lever_position, long time_since_last_change);
  private:
    int _trialstate;
    long _lever_position;
    long _trial_trigger_on;
    long _trial_trigger_off;
    long _time_since_last_change;
    int _min_trigger_on_duration; //in ms
    int _max_trial_duration;// in ms
    int _min_trial_duration;// in ms
    int _iti; // in ms
};

#endif
