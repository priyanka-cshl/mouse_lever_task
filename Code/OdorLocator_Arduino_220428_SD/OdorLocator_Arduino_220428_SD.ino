// ---- adding libraries ------------------------------------------------------
#include <SPI.h> // library for SPI communication - to DAC
#include "trialstates.h" // function to process trial states
#include <Wire.h> // library for I2C communication - to slave Arduinos
#include <DueTimer.h> // Import the ArCOM library
#include "ArCOM.h"
#include "openlooptrialstates.h" // function to process open loop trial states 13.02.18
#include "sequencetrialstates.h"
#include <SD.h> // for open loop
// ----------------------------------------------------------------------------

// set up variables using the SD utility library functions:
const int SDSelect = 53; // SS pin for the SD card
File mySDFile;

// ---- initialize function calls ---------------------------------------------
trialstates trialstates;
openlooptrialstates openlooptrialstates; // open loop trial states 13.02.18
sequencetrialstates sequencetrialstates; // open loop trial states 13.02.18
ArCOM myUSB(SerialUSB); // Create an ArCOM wrapper for the SerialUSB interface
// ----------------------------------------------------------------------------

//pins
int lever_in = A7; // A0 on rig1
int fake_lever_in = A8; // signal generator

int trial_reporter_pin = 41;
int in_target_zone_reporter_pin = 43;
int in_reward_zone_reporter_pin = 45;
int reward_reporter_pin = 47;
int reward_valve_pin = 39; // 8 on rig1
int air_valve = 35; // 9 on rig1
int odor_valves[] = {4, 5, 6, 7}; // {37, 31, 33, 35} on rig1
int odor_valves_3way[] = {33, 27, 29, 31}; // {29, 23, 25, 27} on rig1

//communication related
int dac_spi_pin = 22;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
int motor1_i2c_address = 7;

//variables : lever related
long lever_position = 0L;
long lever_rescaled = 0L;
long lever_rescale_params[] = {25000, 13380}; // {gain, offset}
//int target_params[] = {30000, 25000, 20000}; // {upper bound, target, lower bound}
int fake_target_params[] = {30000, 25000, 20000}; // {upper bound, target, lower bound}
int fake_lever = 0;

//variables : stimulus related
int stimulus_state[] = {0, 0}; // old, new
int actual_stimulus_state = 0;
long stimulus_state_timestamp = micros();
bool in_target_zone[2] = {false, false};
bool timer_override = false; // to disable timer start after serial communication
//int training_stage = 2;

// MFC related and valves related
int which_odor = 0;
bool air_valve_state = false;
bool odor_valve_state = false;
unsigned short odor_vial_states[3] = {0}; // ArCOM aray needs unsigned shorts, trial timing, odor and location

//variables : motor and transfer function related
bool motor_override = false;
const int min_time_since_last_motor_call_default = 10; // in ms
int min_time_since_last_motor_call = 10; // in ms - timer period
unsigned int num_of_locations = 100;
unsigned short transfer_function[99] = {0}; // ArCOM aray needs unsigned shorts
unsigned short transfer_function_temp[99] = {0}; // ArCOM aray needs unsigned shorts
int motor_location = 1;
int offset_location = 1;
int perturbation_offset = 0;
int perturbation_offset_location = 0;
int transfer_function_pointer = 0; // for transfer function calibration
unsigned int my_location = 101;
unsigned int left_first = 1;
int rewarded_locations[2] = {101, 101};
int neutral_locations[2] = {101, 101};

//variables : reward related
int reward_state = 0;
long reward_zone_timestamp = micros();
long trial_off_buffer = 0;
int reward_params[] = {100, 40, 0}; // {hold for, duration, summed hold for} in ms
unsigned short multi_reward_params[] = {200, 10, 10}; // {hold for, duration, trial init reward} in ms for the subsequent rewards within a trial
// 4th entry is reward valve polarity
int multiplerewards = 0; // only one reward per trial
long time_in_target_zone = 0;
int last_target_stay = 0;
//variables : perturbation related - water delivery decoupled from stimulus
bool decouple_reward_and_stimulus = false;

//variables: flip mapping mid-trial
bool flip_lever = false;
bool flip_lever_trial = false;
int use_offset_perturbation = 0;
int offset_perturbation_trial = 0;
int offset_perturbation_trial_typeII = 0;
bool out_of_target_zone = false;
int feedback_halt = 0;
bool feedback_halt_flip_trial = false;
bool feedback_pause_trial = false;
int feedback_halt_duration = 500;
long feedback_halt_timestamp = micros();
long feedback_halt_lever_position = 0L;
int feedback_halt_offset = 0;

//variables : trial related
int trialstate[] = {0, 0}; // old, new
long trial_timestamp = micros();
long trial_trigger_level[] = {52000, 13000}; // trigger On, trigger Off
int trial_trigger_timing[] = {10, 600, 3000}; // trigger hold, trigger smooth, trial min, trial max
int long_iti = 0;
int normal_iti = 200;
int last_trial_duration = 0;
int last_trigger_hold = 0;

// Replay related
int replay_state = 0;
int replay_flag = 0;
int ReplayVal = 0;
int byteHIGH = 0;
int byteLOW = 0;
int current_odor_state = 0;
bool current_reward_state = false;
bool replay_reward_valve_state[2] = {false, false};
bool replay_air_valve_state[2] = {false, false};
int replay_odor_valve_state[2] = {0, 0};

// PID_related - 13.02.18
int PassiveTuning_trial_timing[] = {500, 500, 500, 50, 500, 500}; //motor_settle, pre-odor, odor, purge, post-odor, iti in ms
int PassiveTuning_location = 0;
unsigned short PassiveTuning_param_array[6] = {0}; // ArCOM aray needs unsigned shorts, trial timing, odor and location

//variables : general
int i = 0;
int check = 0;
bool session_just_started = false;
int session_mode = -1; // -1 = idle, 1 = close loop, 2 = open loop (passive tuning), 3 = sequence mode (passive). 4 = replay
int current_session_mode = -1;

//variables : serial communication
long serial_clock = micros();
int FSMheader = 0;
unsigned int num_of_params = 35;
unsigned short param_array[35] = {0}; // ArCOM aray needs unsigned shorts

// odor sequence
unsigned int sequence_params = 9;
unsigned short sequence_array[9] = {0}; // ArCOM aray needs unsigned shorts {121, 1, 2, 1, 2, 1, 500, 500, 500, 500}; //location, odor1-5, pre-odor, odor, post-odor, iti in ms
int sequence_timing[] = {500, 500, 500, 500}; //pre-odor, odor, post-odor, iti in ms
int sequence_location = 0;
int sequence_odors[] = {1, 2, 1, 2, 1};
int stimcount = 0;

// pseudorandom sequnce
unsigned int pseudosequence_params = 13; // 13 locations
unsigned short pseudosequence_array[13] = {0};
int locationcount = 0;

// variables - camera sync
int camera_pin = 49;
bool camera = 0;
int camera_on = 0;

// variables - cleaning
bool odorON = false;
byte whichOdor = 0;
bool cleaningON = false;

void setup()
{
  SerialUSB.begin(115200);

  pinMode(air_valve, OUTPUT);
  digitalWrite(air_valve, LOW);

  for (i = 0; i < 4; i++)
  {
    pinMode(odor_valves[i], OUTPUT);
    digitalWrite(odor_valves[i], LOW);
    pinMode(odor_valves_3way[i], OUTPUT);
    digitalWrite(odor_valves_3way[i], LOW);
  }

  pinMode(reward_valve_pin, OUTPUT);
  digitalWrite(reward_valve_pin, LOW);
  pinMode(in_reward_zone_reporter_pin, OUTPUT);
  digitalWrite(in_reward_zone_reporter_pin, LOW);
  pinMode(in_target_zone_reporter_pin, OUTPUT);
  digitalWrite(in_target_zone_reporter_pin, LOW);
  pinMode(reward_reporter_pin, OUTPUT);
  digitalWrite(reward_reporter_pin, LOW);
  pinMode(trial_reporter_pin, OUTPUT);
  digitalWrite(trial_reporter_pin, LOW);
  pinMode(camera_pin, OUTPUT);
  digitalWrite(camera_pin, LOW);

  // set up SPI
  pinMode (dac_spi_pin, OUTPUT);
  SPI.begin(dac_spi_pin);

  // set up SD card
  SD.begin(SDSelect);

  // set up I2C
  Wire.begin();

  // fill transfer function
  for (i = 0; i < num_of_locations; i++)
  {
    transfer_function[i] = 20;
  }

  // fill stimulus position array
  stimulus_state[0] = 181;
  stimulus_state[1] = 181;

  // Timer for motor update
  Timer3.attachInterrupt(MoveMotor);
  Timer3.start(1000 * min_time_since_last_motor_call_default); // Calls every 10 msec

  // Timer for reward delivery
  Timer4.attachInterrupt(RewardNow);

  // Timer for odor machine cleaning
  Timer5.attachInterrupt(CleaningRoutine);

  // analog read - lever position
  analogReadResolution(12);

  // first call to set up params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
  trialstates.UpdateITI(normal_iti);
  openlooptrialstates.UpdateOpenLoopTrialParams(PassiveTuning_trial_timing); // 13.02.18
}


void loop()
{
  // Special case: TF calibration
  //----------------------------------------------------------------------------
  // 1,2) convert the current entry in TF array to lever position and send to DAC
  //----------------------------------------------------------------------------
  if (session_mode == 0) // TF calibration
  {
    motor_location = transfer_function[transfer_function_pointer];
    SPIWriter(dac_spi_pin, map(motor_location, 0, 255, 0, 65534));
    stimulus_state[1] = motor_location;
  }
  //----------------------------------------------------------------------------

  // For all other situations
  //----------------------------------------------------------------------------
  // 1) process the incoming lever position data - and resend to DAC
  //----------------------------------------------------------------------------
  // read lever position as analog val
  if (fake_lever == 0)
  {
    lever_position = analogRead(lever_in);
  }
  else
  {
    lever_position = analogRead(fake_lever_in);
  }
  // remap from 12-bit to 16-bit
  lever_position = map(lever_position, 0, 4095, 0, 65534);
  // rescale linearly using lever dcoffset and gain to better utilize the
  // available sensor range: assume units are mvolts
  lever_rescaled = (lever_rescale_params[0] * 0.0001) * (lever_position - lever_rescale_params[1]);
  // constrain position values between 0 and 65534
  lever_position = constrain(lever_rescaled, 0, 65534);

  // write lever position to DAC
  if (session_mode > 0)
  {
    SPIWriter(dac_spi_pin, lever_position);
  }

  // For closed loop mode
  //----------------------------------------------------------------------------
  // 2) convert lever position to stimuli given current target zone definition
  //----------------------------------------------------------------------------
  if (session_mode == 1)
  {
    motor_location = map(lever_position, 0, 65534, 0, num_of_locations - 1);
    motor_location = constrain(motor_location, 0, 98); // otherwise weird stuff happens on the trial after an offset trial
    if (flip_lever)
    {
      motor_location = constrain((offset_location - (motor_location - offset_location)), 0, num_of_locations - 1);
    }

    switch (use_offset_perturbation)
    {
      case 0:
        if (feedback_halt == 1)
        {
          // feedback is paused - don't update stimulus state
        }
        else
        {
          stimulus_state[1] = transfer_function[motor_location];
        }
        break;
      case 1:
        //stimulus_state[1] = transfer_function[motor_location];
        out_of_target_zone = !(transfer_function[motor_location] == constrain(transfer_function[motor_location], neutral_locations[0], neutral_locations[1]));
        if (out_of_target_zone && (use_offset_perturbation == 1))
        {
          use_offset_perturbation = 2;
          trial_timestamp = micros() - (1000 * trial_trigger_timing[1]); // reset trial timestamp to give extra time for the trial
        }
        stimulus_state[1] = perturbation_offset_location;
        break;
      case 2:
        stimulus_state[1] = transfer_function[motor_location] + perturbation_offset;
        break;
    }

    // in reward zone or not : if in, odor location ranges between 17 and 48
    in_target_zone[0] = (stimulus_state[1] == constrain(stimulus_state[1], rewarded_locations[0], rewarded_locations[1]));
    if (decouple_reward_and_stimulus)
    {
      in_target_zone[1] = (lever_position == constrain(lever_position, fake_target_params[2], fake_target_params[0]));
    }
    else
    {
      in_target_zone[1] = (stimulus_state[1] == constrain(stimulus_state[1], rewarded_locations[0], rewarded_locations[1]));
    }

    //----------------------------------------------------------------------------
    // 3) update stimulus state, direction etc. if the stimulus_state has changed
    //----------------------------------------------------------------------------
    if (stimulus_state[1] != stimulus_state[0])
    {
      if ( ((micros() - stimulus_state_timestamp) >= 1000 * min_time_since_last_motor_call) )
      {
        stimulus_state_timestamp = micros(); // valid event
        // update reward zone time stamp, if needed
        if (trialstate[0] == 4)
        {
          if (in_target_zone[1] && (reward_state == 1))
            // in trial, entered target zone, and has not received reward in this trial
          {
            reward_zone_timestamp = micros();
            reward_state = 2;
            if (flip_lever_trial && !flip_lever)
            {
              flip_lever = true;
              offset_location = motor_location;
            }
          }
          if (!in_target_zone[1] && (reward_state == 2))
          {
            reward_state = 1; // was in reward zone in this trial, but exited reward zone before getting a reward, retrigger reward availability
            time_in_target_zone = time_in_target_zone + (micros() - reward_zone_timestamp);
            if ((micros() - reward_zone_timestamp) / 1000 > last_target_stay)
            {
              last_target_stay = (micros() - reward_zone_timestamp) / 1000;
            }
          }
          if (multiplerewards > 0)
          {
            if ( in_target_zone[1] && ((reward_state == 4) || (reward_state == 7)) && (micros() - reward_zone_timestamp) <= 1000 * multiplerewards )
            {
              reward_zone_timestamp = micros();
              reward_state = 5;
            }
            if (!in_target_zone[1] && (reward_state == 5))
            {
              reward_state = 4; // was in reward zone in this trial, but exited reward zone before getting a reward, retrigger reward availability
            }
          }
        }
        // update stimulus state
        stimulus_state[0] = stimulus_state[1];
      }
    }

    //----------------------------------------------------------------------------
    // 4) manage reward
    //----------------------------------------------------------------------------
    if (reward_state == 2)
    {
      if ((perturbation_offset != 0) && (!use_offset_perturbation))
      {
        if ((micros() - reward_zone_timestamp) > 900 * reward_params[0])
        {
          reward_state = 1; // reset reward state
          time_in_target_zone = 0; // reset timespent value
          if (offset_perturbation_trial_typeII)
          {
            use_offset_perturbation = 1; // if location offset trial - this will mark the start of perturbation
          }
          else
          {
            use_offset_perturbation = 2;
            trial_timestamp = micros() - (1000 * trial_trigger_timing[1]); // reset trial timestamp to give extra time for the trial
          }
        }
      }

      if ((micros() - reward_zone_timestamp) > 1000 * reward_params[0])
      {
        last_target_stay = (micros() - reward_zone_timestamp) / 1000;
        reward_state = 3; // flag reward valve opening
        time_in_target_zone = 0; // reset timespent value
        trialstates.UpdateITI(normal_iti); // don't impose any ITI
        Timer4.start(1000 * reward_params[1]); // call reward timer
      }
      else if ((time_in_target_zone + (micros() - reward_zone_timestamp)) > 1000 * reward_params[2])
      {
        // summed reward criterion - only applies if its not an offset perturbation trial or
        // if the perturbation has laready been triggered
        if ( (perturbation_offset == 0) || (use_offset_perturbation > 0) )
        {
          reward_state = 3; // flag reward valve opening
          //time_in_target_zone = 0; // reset timespent value
          trialstates.UpdateITI(normal_iti); // don't impose any ITI
          Timer4.start(1000 * reward_params[1]); // call reward timer
        }
      }
    }

    if (reward_state == 5 && ((micros() - reward_zone_timestamp) > 1000 * multi_reward_params[0]))
    {
      reward_state = 6; // flag reward valve opening
      Timer4.start(1000 * multi_reward_params[1]); // call reward timer
    }
    //----------------------------------------------------------------------------
  }

  //----------------------------------------------------------------------------
  // 5) manage reporter pins, valves etc based on time elapsed since last event
  //----------------------------------------------------------------------------
  if (session_mode == 1) // closed - loop
  {
    digitalWrite(trial_reporter_pin, (trialstate[0] == 4)); // active trial?
    if (camera_on)
    {
      digitalWrite(camera_pin, (trialstate[0] == 4)); // active trial?
    }
    else
    {
      digitalWrite(camera_pin, LOW); // active trial?
    }

    digitalWrite(in_target_zone_reporter_pin, in_target_zone[0]); // in_target_zone?
    if (trialstate[0] == 1)
    {
      digitalWrite(in_reward_zone_reporter_pin, HIGH);
    }
    else
    {
      if (perturbation_offset != 0)
      {
        if (offset_perturbation_trial_typeII)
        {
          digitalWrite(in_reward_zone_reporter_pin, use_offset_perturbation == 1);
        }
        else
        {
          digitalWrite(in_reward_zone_reporter_pin, use_offset_perturbation == 2); // in_reward_zone?
        }
      }
      else if ((feedback_halt_flip_trial) || (feedback_pause_trial))
      {
        digitalWrite(in_reward_zone_reporter_pin, (feedback_halt == 1)); // in_reward_zone?
      }
      else
      {
        digitalWrite(in_reward_zone_reporter_pin, (reward_state == 2) || (reward_state == 5)); // in_reward_zone?
      }
    }
  }
  else if ((session_mode == 2) || (session_mode == 3)) // passive tuning or sequences
  {
    //send_odor_to_manifold();
    digitalWrite(trial_reporter_pin, ((trialstate[0] > 0) && (trialstate[0] < 5)) || trialstate[0] == 6); // active trial?
    digitalWrite(in_reward_zone_reporter_pin, ((trialstate[0] == 4) || (trialstate[0] == 6))); // is Odor valve ON?
    digitalWrite(in_target_zone_reporter_pin, ((trialstate[0] == 0) || (trialstate[0] == 5))); // is trial OFF?
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 6) determine next trial state
  //----------------------------------------------------------------------------
  if (timer_override)
  {
    switch (session_mode)
    {
      case 1: // close-loop
        // if trialstate is active and reward has been received
        // - trialstate should be pushed to 0 after a buffer time has elapsed
        // buffer time = multi_reward_params[0] if multiplerewards==0
        // buffer time = multiplerewards if multiplerewards!=0
        // note: reward_zone_timestamp will be updated when reward valve is turned off
        if ( trialstate[0] == 4 && ( (reward_state == 4) || (reward_state == 7) ) && (micros() - reward_zone_timestamp) > trial_off_buffer)
        {
          trialstate[1] = 5;
        }
        else
        {
          trialstate[1] = trialstates.WhichState(trialstate[0], lever_position, (micros() - trial_timestamp));
        }
        break;

      case 2: // passive tuning
        trialstate[1] = openlooptrialstates.WhichState(trialstate[0], (micros() - trial_timestamp));
        break;

      case 3: // sequences
        trialstate[1] = sequencetrialstates.WhichState(trialstate[0], (micros() - trial_timestamp), stimcount);
        break;
    }
  }
  else
  {
    trialstate[1] = 0;
  }

  //----------------------------------------------------------------------------
  // 7) update trial state specific stuff - if trial state changed
  //----------------------------------------------------------------------------
  if (session_mode == 1)
  {
    if (trialstate[1] != trialstate[0]) // trial state changes
    {
      reward_state = (int)(trialstate[1] == 4); // trial was just activated, rewards can be triggered now
      if (trialstate[1] == 5) //trial just ended
      {
        last_trial_duration = (micros() - trial_timestamp) / 1000;
      }
      trial_timestamp = micros();

      if (timer_override)
      {
        switch (trialstate[1])
        {
          case 0:
            which_odor = 0;
            air_valve_state = false;
            send_odor_to_manifold();
            break;
          case 1:
            UpdateTF();
            break;
          case 2:
            // reset long ITI
            if (decouple_reward_and_stimulus)
            {
              trialstates.UpdateITI(normal_iti); // will be changed to zero if animal receives a reward in the upcoming trial
            }
            else
            {
              trialstates.UpdateITI(long_iti); // will be changed to zero if animal receives a reward in the upcoming trial
            }
            //turn on odor/air flow
            which_odor = param_array[0]; // odor vial number
            odor_valve_state = true;
            air_valve_state = true;
            send_odor_to_manifold();
            //UpdateTF();
            break;
          case 4:
            time_in_target_zone = 0; // reset timespent value
            last_target_stay = 0;
            last_trial_duration = 0;
            if (replay_flag == 1)
            {
              replay_flag = 2; // this will begin the writing to SD file
              current_session_mode = session_mode;
            }
            if (replay_flag == 11)
            {
              replay_flag = 22; // this will begin the writing to SD file
              current_session_mode = session_mode;
            }
            if (replay_flag == 3)
            {
              replay_flag = 4; // this will begin the reading from SD file
              session_mode = 4;
              digitalWrite(trial_reporter_pin, HIGH);
            }
            break;
          case 5:
            flip_lever = false;
            use_offset_perturbation = 0;
            feedback_halt = 0;
            // turn on air purge
            which_odor = 0;
            send_odor_to_manifold();
            break;
        }
      }

      trialstate[0] = trialstate[1];
    }

    // extra step needed to turn off purging in case of long ITI
    if (trialstate[1] == 5 && trialstate[0] == 5 && odor_valve_state && (micros() - trial_timestamp) > 1000 * normal_iti)
    {
      //odor_valve_state = true;
      air_valve_state = false;
      send_odor_to_manifold();
    }

    if ((feedback_halt == 1) && (micros() - feedback_halt_timestamp) > 1000 * feedback_halt_duration)
    {
      feedback_halt = 2;
    }

    if (trialstate[1] == 4 && feedback_halt == 0 && feedback_pause_trial == 1 && lever_position < feedback_halt_lever_position)
    {
      feedback_halt = 1;
      feedback_halt_timestamp = micros();
    }

    if (trialstate[1] == 4 && feedback_halt == 0 && feedback_halt_flip_trial == 1 && lever_position < feedback_halt_lever_position)
    {
      stimulus_state[1] = feedback_halt_offset;
      feedback_halt = 1;
      feedback_halt_timestamp = micros();
    }

  }

  if (session_mode == 2)
  {
    if (trialstate[1] != trialstate[0]) // trial state changes
    {
      trial_timestamp = micros();
      if (timer_override)
      {
        switch (trialstate[1])
        {
          case 0: // move motor to desired location and give it time to settle
            if (PassiveTuning_location == 999)
            {
              mySDFile.close();
              mySDFile = SD.open("openloop.txt");
              current_session_mode = 2;
              session_mode = 4;
              replay_flag = 4;
              digitalWrite(trial_reporter_pin, HIGH);
              which_odor = 0;
              odor_valve_state = true; // blank vial on
              air_valve_state = true;
              send_odor_to_manifold();
            }
            else if (PassiveTuning_location == 998)
            {
              current_session_mode = 2;
              session_mode = 4;
              replay_flag = 4;
              digitalWrite(trial_reporter_pin, HIGH);
              which_odor = 0;
              odor_valve_state = true; // blank vial on
              air_valve_state = true;
              send_odor_to_manifold();
            }
            else
            {
              stimulus_state[1] = PassiveTuning_location;
              odor_valve_state = false; // keep odor valve closed (blank vial is Onand going to exhaust)
              air_valve_state = false;
              send_odor_to_manifold();
            }
            break;
          case 1: // pre-odor, no-flow
            which_odor = 0;
            odor_valve_state = true; // blank vial on
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 4: // odor, switch odor vial to odor, turn on flow
            which_odor = PassiveTuning_param_array[0]; // odor vial number
            odor_valve_state = true;
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 6: // buffer state - move odor to next location
            locationcount = locationcount + 1;
            if (locationcount < pseudosequence_params)
            {
              stimulus_state[1] = pseudosequence_array[locationcount];
            }
            else
            {
              trialstate[1] = 2;
              which_odor = 0;
              odor_valve_state = true; // blank vial on
              air_valve_state = true;
              send_odor_to_manifold();
            }
            break;
          case 2: // purge, switch to air vial, flow still on
            which_odor = 0;
            odor_valve_state = true; // blank vial on
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 3: // post-odor, switch to air vial
            which_odor = 0;
            odor_valve_state = true; // keep odor valve closed (blank vial is On and going to mouse)
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 5: // iti - no flow, clean air to exhaust
            odor_valve_state = false; // keep odor valve closed (blank vial is Onand going to exhaust)
            air_valve_state = false;
            send_odor_to_manifold();
            break;
        }
      }
      trialstate[0] = trialstate[1];
    }
  }

  if (session_mode == 3)
  {
    if (trialstate[1] != trialstate[0]) // trial state changes
    {
      trial_timestamp = micros();
      if (timer_override)
      {
        switch (trialstate[1])
        {
          case 0: // move motor to desired location and give it time to settle
            stimulus_state[1] = sequence_location;
            odor_valve_state = false; // keep odor valve closed (blank vial is Onand going to exhaust)
            air_valve_state = false;
            send_odor_to_manifold();
            stimcount = 0;
            break;
          case 1: // pre-odor, no-flow
            which_odor = 0;
            odor_valve_state = true; // blank vial on
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 4: // odor, switch odor vial to odor, turn on flow
            which_odor = sequence_odors[stimcount]; // odor vial number
            odor_valve_state = true;
            air_valve_state = true;
            send_odor_to_manifold();
            stimcount = stimcount + 1;
            break;
          case 2: // in-between odors
            which_odor = 0;
            odor_valve_state = true; // blank vial on
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 3: // post-odor, switch to air vial
            which_odor = 0;
            odor_valve_state = true; // keep odor valve closed (blank vial is On and going to mouse)
            air_valve_state = true;
            send_odor_to_manifold();
            break;
          case 5: // iti - no flow, clean air to exhaust
            odor_valve_state = false; // keep odor valve closed (blank vial is Onand going to exhaust)
            air_valve_state = false;
            send_odor_to_manifold();
            break;
        }
      }
      trialstate[0] = trialstate[1];
    }
  }
  //----------------------------------------------------------------------------

  // handling replay
  if (replay_flag == 4)
  {
    // reward
    if (replay_reward_valve_state[1] != replay_reward_valve_state[0])
    {
      digitalWrite(reward_valve_pin, replay_reward_valve_state[1]);
      digitalWrite(reward_reporter_pin, replay_reward_valve_state[1]);
      replay_reward_valve_state[0] = replay_reward_valve_state[1];
    }
    // air
    if (replay_air_valve_state[1] != replay_air_valve_state[0])
    {
      digitalWrite(air_valve, replay_air_valve_state[1]);
      replay_air_valve_state[0] = replay_air_valve_state[1];
    }
    // odor
    if (replay_odor_valve_state[1] != replay_odor_valve_state[0])
    {
      for (i = 1; i < 5; i++)
      {
        digitalWrite(odor_valves_3way[i - 1], (i == replay_odor_valve_state[1]));
      }
      replay_odor_valve_state[0] = replay_odor_valve_state[1];
    }
  }

  //----------------------------------------------------------------------------
  // 8) Serial handshakes to check for parameter updates etc
  //----------------------------------------------------------------------------
  if (myUSB.available() > 0)
  {
    FSMheader = myUSB.readUint16();
    Timer3.stop();
    switch (round(10 * (FSMheader / 10))) // just a hack to parse out cases into categories
    {
      case 10: // opening/closing handshake
        switch (FSMheader - 10)
        {
          case 0: // opening handshake
            myUSB.writeUint16(5);
            camera_on = 1;
            break;
          case 1: // Acquisition start handshake
            // check if a file can be opened on the SD card
            mySDFile = SD.open("openloop.txt", FILE_WRITE);
            if (mySDFile)
            {
              myUSB.writeUint16(2);
            }
            else
            {
              myUSB.writeUint16(6);
            }
            replay_state = 0;
            replay_flag = 0;
            session_just_started = true;
            session_mode = 1;
            // fill stimulus position array
            stimulus_state[0] = 20;
            stimulus_state[1] = 20;
            odor_valve_state = false;
            air_valve_state = false;
            send_odor_to_manifold();
            timer_override = true;
            camera_on = 0;
            camera = 0;
            break;
          case 2: // Acquisition stop handshake
            mySDFile.close(); // close open loop file on SD card
            myUSB.writeUint16(7);
            session_mode = -1;
            timer_override = false;
            odor_valve_state = false;
            air_valve_state = false;
            send_odor_to_manifold();
            camera_on = 1;
            break;
          case 3: // Cleaning Routine start
            myUSB.writeUint16(3);
            session_mode = -1;
            cleaningON = true;
            odorON = false;
            timer_override = false;
            camera_on = 1;
            Timer5.start(1000 * 1000);
            break;
          case 4: // Cleaning Routine stop
            myUSB.writeUint16(4);
            session_mode = -1;
            cleaningON = false;
            timer_override = false;
            camera_on = 1;
            Timer5.stop();
            break;
          case 5: // open loop start
            // check if a file can be opened on the SD card
            mySDFile = SD.open("openloop.txt", FILE_READ);
            if (mySDFile)
            {
              myUSB.writeUint16(2);
            }
            else
            {
              myUSB.writeUint16(8);
            }
            session_mode = 2;
            // fill stimulus position array
            stimulus_state[0] = 121;
            stimulus_state[1] = 121;
            trialstate[0] = 0;
            trialstate[1] = 0;
            odor_valve_state = false;
            air_valve_state = false;
            send_odor_to_manifold();
            timer_override = true;
            camera_on = 0;
            camera = 0;
            break;
          case 6: // open loop stop
            mySDFile.close(); // close open loop file on SD card
            myUSB.writeUint16(9);
            session_mode = -1;
            odor_valve_state = false;
            air_valve_state = false;
            send_odor_to_manifold();
            trialstate[0] = 0;
            trialstate[1] = 0;
            timer_override = false;
            camera_on = 1;
            break;
          case 7: // pause
            myUSB.writeUint16(7);
            timer_override = false;
            motor_override = true;
            break;
          case 8: //unpause
            myUSB.writeUint16(8);
            timer_override = true;
            motor_override = false;
            break;
          case 9: // Odor Sequence start
            myUSB.writeUint16(9);
            session_mode = 3;
            // fill stimulus position array
            stimulus_state[0] = 121;
            stimulus_state[1] = 121;
            trialstate[0] = 0;
            trialstate[1] = 0;
            odor_valve_state = false;
            air_valve_state = false;
            send_odor_to_manifold();
            timer_override = true;
            camera_on = 0;
            camera = 0;
            trial_timestamp = micros();
            break;
        }
        break;
      case 20: // update variables
        switch (FSMheader - 20)
        {
          case 0:
            num_of_params = myUSB.readUint16(); // get number of params to be updated
            myUSB.readUint16Array(param_array, num_of_params);
            // write in the last hold time from previous trial
            param_array[31] = last_target_stay;
            // if the trial was a failed trial - write 7000
            if (last_trial_duration <= param_array[12])
            {
              param_array[31] = 7000;
            }
            myUSB.writeUint16Array(param_array, num_of_params);
            UpdateAllParams(); // parse param array to variable names and update motor params
            break;
          case 1: // update variables for open loop mode - 23.01.2018
            num_of_params = myUSB.readUint16(); // get number of params to be updated
            myUSB.readUint16Array(PassiveTuning_param_array, num_of_params);
            myUSB.writeUint16Array(PassiveTuning_param_array, num_of_params);
            UpdateOpenLoopParams(); // parse param array to variable names and update motor params
            break;
          case 2:
            num_of_params = myUSB.readUint16(); // get number of params to be updated
            myUSB.readUint16Array(sequence_array, num_of_params);
            myUSB.writeUint16Array(sequence_array, num_of_params);
            UpdateSequenceParams(); // parse param array to variable names and update motor params
            break;
        }
        break;
      case 30: // update transfer function or calibrate transfer function
        switch (FSMheader - 30)
        {
          case 0: // close loop
            num_of_locations = myUSB.readUint16(); // get number of params to be updated
            min_time_since_last_motor_call = min_time_since_last_motor_call_default;
            session_mode = 1;
            if (session_just_started)
            {
              UpdateTF();
            }
            break;
          case 1: // open loop
            num_of_locations = myUSB.readUint16();
            min_time_since_last_motor_call = myUSB.readUint16();
            session_mode = 0;
            break;
        }
        myUSB.readUint16Array(transfer_function_temp, num_of_locations);
        myUSB.writeUint16Array(transfer_function_temp, num_of_locations);
        //myUSB.readUint16Array(transfer_function, num_of_locations);
        //myUSB.writeUint16Array(transfer_function, num_of_locations);
        myUSB.writeUint16(83);
        transfer_function_pointer = 0;
        break;
      case 40: // toggle MFCs or odor valves
        break;
      case 50: // open odor vials
        if (FSMheader > 55)
        {
          air_valve_state = bool(FSMheader - 56);
          send_odor_to_manifold();
        }
        else if (FSMheader == 55)
        {
          myUSB.readUint16Array(odor_vial_states, 4);
          myUSB.writeUint16Array(odor_vial_states, 4);
          update_odor_vials();
        }
        else
        {
          odor_valve_state = FSMheader > 50;
          which_odor = odor_valve_state * (FSMheader - 51);
          send_odor_to_manifold();
        }
        break;
      case 60: // motor related
        switch (FSMheader - 60)
        {
          case 0: // disable override
            motor_override = false;
            break;
          case 1: // enable override
            motor_override = true;
            break;
          case 2: // move to specific location
            my_location = myUSB.readUint16(); // location to move to
            I2Cwriter(motor1_i2c_address, my_location + 10); // home request
            break;
        }
        break;
      case 70: // motor related
        I2Cwriter(motor1_i2c_address, int(FSMheader - 70));
        break;
      case 80: // reward valve related
        switch (FSMheader - 80)
        {
          case 0: // close reward valve
            digitalWrite(reward_valve_pin, LOW);
            break;
          case 1: // open reward valve
            digitalWrite(reward_valve_pin, HIGH);
            break;
          case 2: // open reward valve for reward valve duration
            reward_state = 3; // flag reward valve opening
            Timer4.stop();
            Timer4.start(1000 * reward_params[1]); // call reward timer
            break;
          case 3: // for reward calibration
            for (int i = 0; i < 100; i++)
            {
              digitalWrite(reward_valve_pin, HIGH);
              delay(reward_params[1]);
              digitalWrite(reward_valve_pin, LOW);
              delay(500);
            }
            break;
          case 4: // Multi_reward_params
            //serial_clock = millis();
            //while ( myUSB.available() < 2 && (millis() - serial_clock) < 1000 )
            //{ } // wait for serial input or time-out
            //myUSB.readUint16Array(multi_reward_params, 3);
            //myUSB.writeUint16Array(multi_reward_params, 3);
            break;
          case 5: // PID_reward
            digitalWrite(reward_valve_pin, HIGH);
            digitalWrite(reward_reporter_pin, HIGH);
            delay(PassiveTuning_param_array[10]);
            digitalWrite(reward_valve_pin, LOW);
            digitalWrite(reward_reporter_pin, LOW);
            break;
        }
        break;
      case 90: // SPI communication
        SPIWriter(dac_spi_pin, 0);
        delay(250);
        SPIWriter(dac_spi_pin, 65535);
        delay(250);
        break;
    }

    if (timer_override)
    {
      Timer3.start(1000 * min_time_since_last_motor_call); // Calls every 10 msec
    }
  }
  //----------------------------------------------------------------------------

} // end of loop()

void SPIWriter (int spi_pin, int ValueToWrite)
{
  SPI.beginTransaction(SPISettings(16000000, MSBFIRST, SPI_MODE0));
  digitalWrite(spi_pin, LOW);
  SPI.transfer(spi_pin, highByte(ValueToWrite), SPI_CONTINUE);
  SPI.transfer(spi_pin, lowByte(ValueToWrite));
  digitalWrite(spi_pin, HIGH);
  SPI.endTransaction();
}

void I2Cwriter (int wire_address, int DataToWrite)
{
  Wire.beginTransmission(wire_address);
  Wire.write(DataToWrite);
  Wire.endTransmission();
}

void UpdateAllParams()
{
  myUSB.writeUint16(89);
  use_offset_perturbation = 0;
  // parse param array to variable names
  //which_odor = param_array[0]; // odor vial number
  camera_on = param_array[1];
  lever_rescale_params[0] = param_array[2]; // gain, offset
  lever_rescale_params[1] = param_array[3];
  reward_params[0] = param_array[4]; // target hold
  multi_reward_params[0] = param_array[5]; // hold-II
  reward_params[2] = param_array[6]; // summed hold
  reward_params[1] = param_array[7]; // reward-I valve time
  multi_reward_params[1] = param_array[8]; // reward-II valve time
  trial_trigger_level[0] = param_array[9]; // trigger high lever value
  trial_trigger_level[1] = param_array[10]; // trigger low lever value
  for (i = 0; i < 3; i++)
  {
    trial_trigger_timing[i] = param_array[11 + i]; // trig_hold, min_trial, max_trial
  }
  multiplerewards = param_array[14]; // IRI (0 if multiple rewards is off)
  trial_off_buffer = param_array[15];

  // target zone limits - in terms of motor location
  rewarded_locations[0] = param_array[21] - param_array[20];
  rewarded_locations[1] = param_array[21] + param_array[20];

  long_iti = param_array[23];
  flip_lever_trial = (param_array[24] == 4);
  offset_perturbation_trial = (param_array[24] == 5);
  offset_perturbation_trial_typeII = (param_array[24] == 6);
  feedback_halt_flip_trial = (param_array[24] == 10);
  feedback_pause_trial = (param_array[24] == 9);
  if (offset_perturbation_trial)
  {
    perturbation_offset = param_array[25] - param_array[21];
  }
  else if (offset_perturbation_trial_typeII)
  {
    perturbation_offset = param_array[25] - param_array[21];
    perturbation_offset_location = param_array[25];
    neutral_locations[0] = rewarded_locations[0] - (2 * param_array[20]);
    neutral_locations[1] = rewarded_locations[1] + (2 * param_array[20]);
  }
  else
  {
    perturbation_offset = 0;
  }

  for (i = 0; i < 3; i++)
  {
    fake_target_params[i] = param_array[26 + i]; // high lim, target, low lim
  }

  decouple_reward_and_stimulus = (fake_target_params[2] > 0);

  if ((feedback_halt_flip_trial) || (feedback_pause_trial))
  {
    feedback_halt_duration = param_array[25];
    feedback_halt_lever_position = param_array[27];
  }
  else
  {
    feedback_halt_duration = 0;
    //fake_target_params[1] = 0;
    //decouple_reward_and_stimulus = false;
  }

  if (feedback_halt_flip_trial)
  {
    feedback_halt_offset = param_array[26];
  }
  else
  {
    feedback_halt_offset = 0;
  }

  //delay_feedback_by = param_array[29];
  // training_stage = param_array[30];

  // Handle Open loop and Replay states
  if (replay_state != param_array[30]) // state transitions
  {
    replay_state = param_array[30];
    switch (replay_state)
    {
      case 0:
        replay_flag = 0;
        mySDFile.close();
        break;
      case 12: // stop recording - halt flip - but don't close file
        replay_flag = 0;
        //mySDFile.close();
        break;
      case 1:
        // start a new open loop recording
        // 1) delete old file and create new
        SD.remove("openloop.txt");
        mySDFile = SD.open("openloop.txt", FILE_WRITE);
        replay_flag = 1; // this will update to 2 on next trial start and file writing will begin
        break;
      case 10:
        // start a new halt flip recording
        // 1) delete old file and create new
        SD.remove("openloop.txt");
        mySDFile = SD.open("openloop.txt", FILE_WRITE);
        replay_flag = 1; // this will update to 2 on next trial start and file writing will begin
        replay_state = 11;
        break;
      case 11:
        // append to open loop recording
        // SD.remove("openloop.txt");
        // mySDFile = SD.open("openloop.txt", FILE_WRITE);
        replay_flag = 11; // this will update to 2 on next trial start and file writing will begin
        break;
      case 2:
        // Replay from file
        mySDFile = SD.open("openloop.txt");
        replay_flag = 3; // this will update to 4 on next trial start and file reading will begin
        break;

    }
  }

  // update trial state params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
}

void UpdateOpenLoopParams() // 23.01.2018
{
  myUSB.writeUint16(98);
  //trialstate[0] = 5;
  // parse param array to variable names
  //which_odor = PassiveTuning_param_array[0]; // odor vial number
  PassiveTuning_location = PassiveTuning_param_array[1]; // desired location
  if (PassiveTuning_param_array[1] == 800)
  {
    trialstate[0] = 5;
    locationcount = 0;
    pseudosequence_params = num_of_params - 11;
    for (i = 0; i < pseudosequence_params; i++)
    {
      pseudosequence_array[i] = PassiveTuning_param_array[11 + i];
    }
    PassiveTuning_location = pseudosequence_array[locationcount];
    PassiveTuning_param_array[5] = 0; // hack to keep rolling back to odor state
  }
  for (i = 0; i < 6; i++)
  {
    PassiveTuning_trial_timing[i] = PassiveTuning_param_array[2 + i]; // motor_settle, pre-odor, odor, post-odor, iti in ms
  }
  lever_rescale_params[0] = PassiveTuning_param_array[8]; // gain, offset
  lever_rescale_params[1] = PassiveTuning_param_array[9];
  //reward_params[1] = PassiveTuning_param_array[10];
  // update trial state params
  openlooptrialstates.UpdateOpenLoopTrialParams(PassiveTuning_trial_timing);

}

void UpdateSequenceParams() // 05.05.2021
{
  myUSB.writeUint16(99);
  trialstate[0] = 5;
  // parse param array to variable names
  sequence_location = sequence_array[0]; // desired location
  stimulus_state[1] = sequence_array[0];
  for (i = 1; i < 6; i++)
  {
    sequence_odors[i - 1] = sequence_array[i];
  }
  for (i = 6; i < 10; i++)
  {
    sequence_timing[i - 6] = sequence_array[i]; // pre-odor, odor, post-odor, iti in ms
  }
  sequencetrialstates.UpdateSequenceTrialParams(sequence_timing);
}

void MoveMotor()
{
  //digitalWrite(camera_pin, camera_on);
  if (!motor_override)// && (trialstate[1] == 4))
  {
    if (replay_flag == 4)
    {
      // read stim state
      if (mySDFile.available())
      {
        byteHIGH = mySDFile.read();
        byteLOW = mySDFile.read();
        ReplayVal = byteHIGH * 256 + byteLOW;
        if (ReplayVal == 65000)
        {
          replay_flag = 5;
          session_mode = current_session_mode;
          digitalWrite(trial_reporter_pin, LOW);
          trialstate[0] = 5; trialstate[1] = 5;
          trial_timestamp = micros();
        }
        else
        {
          replay_reward_valve_state[1] = (ReplayVal >= 20000);
          ReplayVal = ReplayVal - 10000 * (1 + replay_reward_valve_state[1]);
          stimulus_state[1] = ReplayVal % 1000;
          ReplayVal = (ReplayVal - stimulus_state[1]) / 1000;
          if (ReplayVal >= 5)
          {
            replay_air_valve_state[1] = true;
            replay_odor_valve_state[1] = ReplayVal - 4;
          }
          else
          {
            replay_air_valve_state[1] = false;
          }

          I2Cwriter(motor1_i2c_address, 10 + stimulus_state[1]);
        }
      }
      else
      {
        replay_flag = 5;
        session_mode = current_session_mode;
        digitalWrite(trial_reporter_pin, LOW);
      }
    }
    else
    {
      I2Cwriter(motor1_i2c_address, 10 + stimulus_state[1]);
      if (replay_flag == 2)
      {
        // write to SD file
        ReplayVal = 10000 * (current_reward_state + 1) + 1000 * (current_odor_state) + stimulus_state[1];
        mySDFile.write(highByte(ReplayVal));
        mySDFile.write(lowByte(ReplayVal));
      }
      if (replay_flag == 22)
      {
        // write to SD file
        mySDFile.write(highByte(65000));
        mySDFile.write(lowByte(65000));
        ReplayVal = 10000 * (current_reward_state + 1) + 1000 * (current_odor_state) + stimulus_state[1];
        mySDFile.write(highByte(ReplayVal));
        mySDFile.write(lowByte(ReplayVal));
        replay_flag = 2;
      }
    }

  }

  if (session_mode == 0)
  {
    // roll over the TF array pointer
    transfer_function_pointer = (transfer_function_pointer + 1) % num_of_locations;
  }
  //camera = camera_on * (!camera);
  //digitalWrite(camera_pin, camera);
  //digitalWrite(camera_pin, LOW);
}

void RewardNow()
{
  if ( ((reward_state == 3) || (reward_state == 6)) )//&& timer_override )
  {
    digitalWrite(reward_valve_pin, HIGH);
    digitalWrite(reward_reporter_pin, HIGH);
    reward_state = reward_state + 1;
    reward_zone_timestamp = micros();
    current_reward_state = true;
  }
  else if (reward_state == -1)
  {
    digitalWrite(reward_valve_pin, HIGH);
    digitalWrite(reward_reporter_pin, HIGH);
    reward_state = reward_state + 1;
  }
  else
  {
    Timer4.stop();
    digitalWrite(reward_valve_pin, LOW);
    digitalWrite(reward_reporter_pin, LOW);
    current_reward_state = false;
  }
}

void UpdateTF()
{
  for (i = 0; i < num_of_locations; i++)
  {
    transfer_function[i] = transfer_function_temp[i];
  }
  session_just_started = false;
}

void CleaningRoutine()
{
  // odorON = true,false; whichOdor = 0,1,2,3;
  odorON = !odorON; // toggle the state of the final valves
  air_valve_state = odorON;
  odor_valve_state = odorON;
  if (odorON)
  {
    // update the odor vial index
    whichOdor = (whichOdor + 1) % 4;
    which_odor = whichOdor;
  }
  send_odor_to_manifold ();
}

void open_odor_vial (int myvial, bool myvialstate)
{
  digitalWrite(odor_valves[myvial], myvialstate);
}

void update_odor_vials ()
{
  myUSB.writeUint16(51);
  for (i = 0; i < 4; i++)
  {
    digitalWrite(odor_valves[i], odor_vial_states[i]);
  }
}

void send_odor_to_manifold ()
{
  for (i = 0; i < 4; i++)
  {
    digitalWrite(odor_valves_3way[i], (odor_valve_state) && (i == which_odor));
  }
  current_odor_state = odor_valve_state * (1 + which_odor);
  digitalWrite(air_valve, air_valve_state); // open air valve
  current_odor_state = current_odor_state + 4 * (air_valve_state);
}
