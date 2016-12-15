// ---- adding libraries ------------------------------------------------------
#include <SPI.h> // library for SPI communication - to DAC
#include "trialstates.h" // function to process trial states
#include <Wire.h> // library for I2C communication - to slave Arduinos
#include <DueTimer.h> // Import the ArCOM library
#include "ArCOM.h"
// #include "LeverToStimulus.h" // function to convert lever position to stimuli
// ----------------------------------------------------------------------------

// ---- initialize function calls ---------------------------------------------
trialstates trialstates;
ArCOM myUSB(SerialUSB); // Create an ArCOM wrapper for the SerialUSB interface
// ----------------------------------------------------------------------------

//pins
int lever_in = A0; // A0-A8, changed briefly to get signal generator IN
int trial_reporter_pin = 41;
int in_target_zone_reporter_pin = 43;
int in_reward_zone_reporter_pin = 45;
int reward_reporter_pin = 47;
int reward_valve_pin = 8;
int target_valves[] = {9, 10};
//int distractor_valves[] = {35, 39};
//int target_MFC[] = {23, 25};
//int distractor_MFC[] = {39, 33};

//communication related
int dac_spi_pin = 22;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
int motor1_i2c_address = 7;
//int motor2_i2c_address = 8;

//variables : lever related
long lever_position = 0L;
long lever_rescaled = 0L;
long lever_rescale_params[] = {25000, 13380}; // {gain, offset}
int target_params[] = {30000, 25000, 20000}; // {upper bound, target, lower bound}
int fake_target_params[] = {30000, 25000, 20000}; // {upper bound, target, lower bound}
int close_loop_mode = 1; // motor moves in sync with lever/analog signal

//variables : stimulus related
int target_which = 1; // stim A is target
bool target_on = true;
int stimulus_state[] = {0, 0}; // old, new
long stimulus_state_timestamp = micros();
byte stimulus_position_array[1199] = {101};
const int stimulus_array_size = 1200;
int stimulus_writepointer = 0;
int stimulus_readpointer = 0;
int delay_feedback_by = 0; // in timer periods (max = 1200)
bool in_target_zone[2] = {false, false};
bool timer_override = false; // to disable timer start after serial communication
int training_stage = 2;

////variables : distractor related
//bool distractor = false;
//int distractor_position_array[255] = {0};
//unsigned long distractor_timestamp_array[255] = {micros()};
//int distractor_writepointer = 0;
//int distractor_readpointer = 0;
//int delay_distractor_by = 20000; // in milliseconds

// MFC related and valves related
bool target_valve_state[2] = {false, false};
//bool distractor_valve_state = false;

//variables : motor and transfer function related
bool motor_override = false;
const int min_time_since_last_motor_call_default = 10; // in ms
int min_time_since_last_motor_call = 10; // in ms - timer period
unsigned int num_of_locations = 100;
unsigned short transfer_function[99] = {0}; // ArCOM aray needs unsigned shorts
int motor_location = 1;
int transfer_function_pointer = 0; // for transfer function calibration
unsigned int my_location = 101;

//variables : reward related
int reward_state = 0;
long reward_zone_timestamp = micros();
int reward_params[] = {100, 40}; // {hold for, duration} in ms

//variables : perturbation related - water delivery decoupled from stimulus
bool decouple_reward_and_stimulus = false;
int fake_stimulus_state[] = {0, 0};
long fake_stimulus_state_timestamp = micros();
bool in_fake_target_zone[] = {false, false};

//variables : trial related
int trialstate[] = {0, 0}; // old, new
long trial_timestamp = micros();
long trial_trigger_level[] = {52000, 13000}; // trigger On, trigger Off
int trial_trigger_timing[] = {10, 20, 600, 3000}; // trigger hold, trigger smooth, trial min, trial max

//variables : general
int i = 0;
int check = 0;

//variables : serial communication
long serial_clock = micros();
int FSMheader = 0;
unsigned int num_of_params = 30;
unsigned short param_array[30] = {0}; // ArCOM aray needs unsigned shorts

void setup()
{
  SerialUSB.begin(115200);

  for (i = 0; i < 2; i++)
  {
    pinMode(target_valves[i], OUTPUT);
    digitalWrite(target_valves[i], LOW);
    //    pinMode(target_MFC[i], OUTPUT);
    //    digitalWrite(target_MFC[i], LOW);
    //    pinMode(distractor_MFC[i], OUTPUT);
    //    digitalWrite(distractor_MFC[i], LOW);
    //    pinMode(distractor_valves[i], OUTPUT);
    //    digitalWrite(distractor_valves[i], LOW);
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

  // set up SPI
  pinMode (dac_spi_pin, OUTPUT);
  SPI.begin(dac_spi_pin);

  // set up I2C
  Wire.begin();

  // fill transfer function
  for (i = 0; i < num_of_locations; i++)
  {
    transfer_function[i] = 101;
  }

  // fill stimulus position array
  for (i = 0; i < stimulus_array_size; i++)
  {
    stimulus_position_array[i] = 101;
  }

  // Timer for motor update
  Timer3.attachInterrupt(MoveMotor);
  Timer3.start(1000 * min_time_since_last_motor_call_default); // Calls every 10 msec

  // Timer for reward delivery
  Timer4.attachInterrupt(RewardNow);
  //Timer3.start(1000 * min_time_since_last_motor_call_default); // Calls every 10 msec
  
  // analog read - lever position
  analogReadResolution(12);

  // first call to set up params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
}


void loop()
{
  //----------------------------------------------------------------------------
  // 1) process the incoming lever position data - and resend to DAC
  //----------------------------------------------------------------------------
  // read lever position as analog val
  lever_position = analogRead(lever_in);
  // remap from 12-bit to 16-bit
  lever_position = map(lever_position, 0, 4095, 0, 65534);
  // rescale linearly using lever dcoffset and gain to better utilize the
  // available sensor range: assume units are mvolts
  lever_rescaled = (lever_rescale_params[0] * 0.0001) * (lever_position - lever_rescale_params[1]);
  // constrain position values between 0 and 65534
  lever_position = constrain(lever_rescaled, 0, 65534);
  // write lever position to DAC
  if (close_loop_mode)
  {
    SPIWriter(dac_spi_pin, lever_position);
    //----------------------------------------------------------------------------

    //----------------------------------------------------------------------------
    // 2) convert lever position to stimuli given current target zone definition
    //----------------------------------------------------------------------------

    // stimulus_state[1] = LeverToStimulus.WhichZone(1, lever_position);
    motor_location = map(lever_position, 0, 65534, 0, num_of_locations - 1);
    stimulus_state[1] = transfer_function[motor_location];
  }
  else
  {
    // write motor command position to DAC
    SPIWriter(dac_spi_pin, 600 * (motor_location - 100));
    //----------------------------------------------------------------------------
    // 1,2) convert the current entry in TF array to lever position and send to DAC
    //----------------------------------------------------------------------------
    motor_location = transfer_function[transfer_function_pointer];
    stimulus_state[1] = motor_location;
  }

  // in reward zone or not : if in, odor location ranges between 17 and 48
  for (i = 0; i < 2; i++)
  {
    in_target_zone[i] = (lever_position == constrain(lever_position, target_params[2], target_params[0]));
  }
  // do the same for the fake target zone condition
  // used only if water delivery is uncoupled from stimulus state
  if (decouple_reward_and_stimulus)
  {
    // fake_stimulus_state[1] = LeverToStimulus.WhichZone(2, lever_position);
    motor_location = map(lever_position, 0, 65534, 0, num_of_locations - 1);
    fake_stimulus_state[1] = transfer_function[motor_location];
    for (i = 0; i < 2; i++)
    {
      in_fake_target_zone[i] = (lever_position == constrain(lever_position, target_params[2], target_params[0]));
    }
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 3) update stimulus state, direction etc. if the stimulus_state has changed
  //----------------------------------------------------------------------------
  if (stimulus_state[1] != stimulus_state[0])
  {
    if ( ((micros() - stimulus_state_timestamp) >= 1000 * min_time_since_last_motor_call) )
    {
      stimulus_state_timestamp = micros(); // valid event
      // update reward zone time stamp, if needed
      if (!decouple_reward_and_stimulus && (trialstate[0] == 4))
      {
        if (in_target_zone[1] && (reward_state == 1)) 
        // in trial, entered target zone, and has not received reward in this trial
        {
          reward_zone_timestamp = micros();
          reward_state = 2;
        }
        if (!in_target_zone[1] && (reward_state == 2))
        {
          reward_state = 1; // was in reward zone in this trial, but exited reward zone before getting a reward, retrigger reward availability
        }
      }

      // update stimulus state
      stimulus_state[0] = stimulus_state[1];
    }
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 4) process the 'fake target' when reward is decoupled from stimulus
  //----------------------------------------------------------------------------
  if ( (decouple_reward_and_stimulus) && (fake_stimulus_state[1] != fake_stimulus_state[0]) )
  {
    if ( ((micros() - fake_stimulus_state_timestamp) >= 1000 * min_time_since_last_motor_call) )
    {
      fake_stimulus_state_timestamp = micros(); // valid event
      if (in_fake_target_zone[1])
      { // currently in reward zone
        if (reward_state == 1 && trialstate[0] == 4)
        { // just entered reward zone
          reward_zone_timestamp = micros();
          //reward_state = 2;
        }
      }
      else if (trialstate[0] == 4)
      {
        reward_state = 1; // exited reward zone
      }
      fake_stimulus_state[0] = fake_stimulus_state[1];
    }
  }
  //----------------------------------------------------------------------------


  //----------------------------------------------------------------------------
  // 7) manage reward
  //----------------------------------------------------------------------------
  if (reward_state == 2 && ((micros() - reward_zone_timestamp) > 1000 * reward_params[0]))
  {
    reward_state = 3; // flag reward valve opening
    Timer4.start(1000 * reward_params[1]); // call reward timer
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 8) manage reporter pins, valves etc based on time elapsed since last event
  //----------------------------------------------------------------------------
  digitalWrite(target_valves[0], (target_valve_state[0] || (trialstate[0] == 4) || !close_loop_mode) ); // open odor valve
  digitalWrite(target_valves[1], (target_valve_state[1] || (trialstate[0] == 4) || !close_loop_mode) ); // open air valve
  digitalWrite(trial_reporter_pin, (trialstate[0] == 4)); // active trial?
  digitalWrite(in_target_zone_reporter_pin, in_target_zone[1]); // in_target_zone?
  digitalWrite(in_reward_zone_reporter_pin, (reward_state == 2)); // in_reward_zone?
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 6) determine trial mode
  //----------------------------------------------------------------------------
  if (training_stage == 2)
  {
    trialstate[1] = 4 * in_target_zone[1];
  }
  else
  {
    trialstate[1] = trialstates.WhichState(trialstate[0], lever_position, (micros() - trial_timestamp));
  }

  if (trialstate[1] != trialstate[0]) // trial state changes
  {
    reward_state = (int)(trialstate[1] == 4); // trial was just activated, rewards can be triggered now
    if (trialstate[1] > trialstate[0])
    {
      trial_timestamp = micros();
    }
    trialstate[0] = trialstate[1];
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 7) Serial handshakes to check for parameter updates etc
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
            break;
          case 1: // Acquisition start handshake
            myUSB.writeUint16(6);
            stimulus_writepointer = 0;
            timer_override = true;
            break;
          case 2: // Acquisition stop handshake
            myUSB.writeUint16(7);
            timer_override = false;
            break;
        }
        break;
      case 20: // update variables
        serial_clock = millis();
        while ( myUSB.available() < 2 && (millis() - serial_clock) < 1000 )
        { } // wait for serial input or time-out
        if (myUSB.available() < 2)
        {
          myUSB.writeInt16(-1);
        }
        else
        {
          num_of_params = myUSB.readUint16(); // get number of params to be updated
          myUSB.readUint16Array(param_array, num_of_params);
          myUSB.writeUint16Array(param_array, num_of_params);
          UpdateAllParams(); // parse param array to variable names and update motor params
        }
        break;
      case 30: // update transfer function or calibrate transfer function
        serial_clock = millis();
        while ( myUSB.available() < 2 && (millis() - serial_clock) < 10000 )
        { } // wait for serial input or time-out
        if (myUSB.available() < 2)
        {
          myUSB.writeInt16(300);
        }
        else
        {
          switch (FSMheader - 30)
          {
            case 0: // close loop
              num_of_locations = myUSB.readUint16(); // get number of params to be updated
              min_time_since_last_motor_call = min_time_since_last_motor_call_default;
              close_loop_mode = 1;
              break;
            case 1: // open loop
              num_of_locations = myUSB.readUint16();
              min_time_since_last_motor_call = myUSB.readUint16();
              close_loop_mode = 0;
              break;
          }
          myUSB.readUint16Array(transfer_function, num_of_locations);
          myUSB.writeUint16Array(transfer_function, num_of_locations);
          myUSB.writeUint16(unsigned int (83));
          transfer_function_pointer = 0;
        }
        break;
      case 40: // toggle MFCs or odor valves
        switch (FSMheader - 40)
        {
          case 0: // MFCs OFF
            for (i = 0; i < 2; i++)
            {
              //digitalWrite(target_MFC[i], LOW);
            }
            break;
          case 1: // MFCs ON
            for (i = 0; i < 2; i++)
            {
              //digitalWrite(target_MFC[i], HIGH);
            }
            break;
          case 2: // MFCs OFF
            for (i = 0; i < 2; i++)
            {
              //digitalWrite(distractor_MFC[i], LOW);
            }
            break;
          case 3: // MFCs ON
            for (i = 0; i < 2; i++)
            {
              //digitalWrite(distractor_MFC[i], HIGH);
            }
            break;
          case 4: // target valves
            target_valve_state[0] = false;
            break;
          case 5: // target valves
            target_valve_state[0] = true;
            break;
          case 6: // target valves
            target_valve_state[1] = false;
            break;
          case 7: // target valves
            target_valve_state[1] = true;
            break;
        }
        break;
      case 50: // update motor variables
        serial_clock = millis();
        while ( myUSB.available() < 2 && (millis() - serial_clock) < 1000 )
        { } // wait for serial input or time-out
        if (myUSB.available() < 2)
        {
          myUSB.writeInt16(-1);
        }
        else
        {
          num_of_params = myUSB.readUint16(); // get number of params to be updated
          //myUSB.readUint16Array(motor_zone_limits, num_of_params);
          //myUSB.writeUint16Array(motor_zone_limits, num_of_params);
          UpdateMotorParams(); // parse param array to variable names and update motor params
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
  myUSB.writeUint16(unsigned int (89));
  // parse param array to variable names
  // param_array[0-1] : [sample_rate refresh_rate]
  lever_rescale_params[0] = param_array[2]; // gain, offset
  lever_rescale_params[1] = param_array[3];
  reward_params[0] = param_array[4];
  reward_params[1] = param_array[5];
  // param_array[6-7] : [rewards_per_block perturb_probability]
  trial_trigger_level[0] = param_array[8];
  trial_trigger_level[1] = param_array[9];
  for (i = 0; i < 4; i++)
  {
    trial_trigger_timing[i] = param_array[10 + i]; // trig_hold, trig_smooth, min_trial, max_trial
  }
  // param[14] = timestamp
  target_which = param_array[15];
  for (i = 0; i < 3; i++)
  {
    target_params[i] = param_array[16 + i]; // high lim, target, low lim
  }
  // params[19-21] = 'target_locations' 'skip_locations' 'offtarget_locations'
  target_on = (param_array[22] > 0);
  delay_feedback_by = ((int)target_on) * (param_array[22] - 1) / min_time_since_last_motor_call;
  // ensure that the dlay does not exceed buffer size
  delay_feedback_by = constrain(delay_feedback_by, 0, stimulus_array_size);

  //distractor = (param_array[23] > 0);
  //delay_distractor_by = ((int)distractor) * (param_array[23] - 1);
  for (i = 0; i < 3; i++)
  {
    fake_target_params[i] = param_array[24 + i]; // high lim, target, low lim
  }
  decouple_reward_and_stimulus = (fake_target_params[1] > 0);
  //param_array[27] = TF size;
  training_stage = param_array[28];
  // update motor targets
  // LeverToStimulus.UpdateTargetParams(target_params, fake_target_params, trial_trigger_level[1]);

  // update trial state params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
}

void UpdateMotorParams()
{
  myUSB.writeUint16(89);
}

void MoveMotor()
{
  // read 'delayed' state
  if (!motor_override)
  {
    stimulus_readpointer = (stimulus_writepointer + delay_feedback_by) % stimulus_array_size;
    if (stimulus_position_array[stimulus_readpointer] > 0)
    {
      I2Cwriter(motor1_i2c_address, 10 + stimulus_position_array[stimulus_readpointer]);
    }
  }
  // write the new state
  stimulus_writepointer = (stimulus_writepointer + 1) % stimulus_array_size;
  stimulus_position_array[stimulus_writepointer] = stimulus_state[1];

  if (!close_loop_mode)
  {
    // roll over the TF array pointer
    transfer_function_pointer = (transfer_function_pointer + 1) % num_of_locations;
  }
}

void RewardNow()
{
  if (reward_state == 3)
  {
    digitalWrite(reward_valve_pin, HIGH);
    digitalWrite(reward_reporter_pin, HIGH);
    reward_state = 4;
  }
  else
  {
    Timer4.stop();
    digitalWrite(reward_valve_pin, LOW);
    digitalWrite(reward_reporter_pin, LOW);
  }
}

