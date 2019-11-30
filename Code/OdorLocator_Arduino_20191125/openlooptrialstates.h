/* Standalone function to evaluate the current trialstate
  November 27, 2015
*/

#ifndef openlooptrialstates_h
#define openlooptrialstates_h

#include "Arduino.h"

class openlooptrialstates
{
  public:
    openlooptrialstates();
    void UpdateOpenLoopTrialParams(int trial_time[]);
    int WhichState(int openlooptrialstate, long time_since_last_change);
  private:
    int _motor_settle_duration; // in ms
    int _pre_odor_duration; //in ms
    int _odor_duration; // in ms
    int _purge_duration; // in ms
    int _post_odor_duration; // in ms
    int _iti_duration; // in ms
    long _time_since_last_change;
    int _openlooptrialstate;
};

#endif

