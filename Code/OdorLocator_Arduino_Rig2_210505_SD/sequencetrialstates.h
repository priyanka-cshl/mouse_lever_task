/* Standalone function to evaluate the current trialstate
  November 27, 2015
*/

#ifndef sequencetrialstates_h
#define sequencetrialstates_h

#include "Arduino.h"

class sequencetrialstates
{
  public:
    sequencetrialstates();
    void UpdateSequenceTrialParams(int trial_time[]);
    int WhichState(int sequencetrialstate, long time_since_last_change, int stimcount);
  private:
    int _pre_odor_duration; //in ms
    int _odor_duration; // in ms
    int _post_odor_duration; // in ms
    int _iti_duration; // in ms
    long _time_since_last_change;
    int _sequencetrialstate;
    int _stimcount
};

#endif
