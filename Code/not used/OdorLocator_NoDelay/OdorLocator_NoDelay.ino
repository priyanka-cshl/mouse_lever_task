// ---- adding libraries ------------------------------------------------------
#include <SPI.h> // library for SPI communication - to DAC
#include "trialstates.h" // function to process trial states
// #include "LeverToStimulus.h" // function to convert lever position to stimuli
#include <Wire.h> // library for I2C communication - to slave Arduinos
// ----------------------------------------------------------------------------

// ---- initialize function calls ---------------------------------------------
trialstates trialstates;
// LeverToStimulus LeverToStimulus;
// ----------------------------------------------------------------------------

//pins
int lever_in = A0; // A0-A8, changed briefly to get signal generator IN
int trial_reporter_pin = 41;
int in_target_zone_reporter_pin = 43;
int in_reward_zone_reporter_pin = 45;
int reward_reporter_pin = 47;
int reward_valve_pin = 39;
int target_MFC[] = {23, 25};
int target_valves[] = {27, 29};
int distractor_MFC[] = {31, 33};
int distractor_valves[] = {35, 37};
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
int stimulus_position_array[255] = {0};
unsigned long stimulus_state_timestamp_array[255] = {micros()};
int stimulus_writepointer = 0;
int stimulus_readpointer = 0;
int delay_feedback_by = 0; // in milliseconds
bool in_target_zone[2] = {false, false};

////variables : distractor related
//bool distractor = false;
//int distractor_position_array[255] = {0};
//unsigned long distractor_timestamp_array[255] = {micros()};
//int distractor_writepointer = 0;
//int distractor_readpointer = 0;
//int delay_distractor_by = 20000; // in milliseconds

// MFC related
bool target_valve_state = false;
bool distractor_valve_state = false;

//variables : motor related
bool motor_override = false;
bool motor_direction = true;
int is_direction_changed = 0;
int motor_locations_per_zone = 16; // motor positions per zone
int min_time_since_last_motor_call = 10; // in ms
const int min_time_since_last_motor_call_default = 10; // in ms
int motor_zone_limits[] = {0, 25, 26, 44, 45, 70}; // motor zones
int num_of_locations = 101;
int transfer_function[100] = {0};
int motor_location = 1;

// for transfer function calibration
//int transfer_function_order[101] = {0};
int transfer_function_pointer = 0;

//variables : reward related
int reward_state = 0;
long reward_zone_timestamp = micros();
int reward_params[] = {100, 40}; // {hold for, duration} in ms
long reward_on_timestamp = micros();
int reward_override = 0;
long reward_override_timestamp = micros();

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

//variables : serial communication
long serial_clock = micros();
int FSMheader = 0;
int param_index = 0;
int num_of_params = 5;
int param_array[] = {};
int param_value = 0;

void setup()
{
  for (i = 0; i < 2; i++)
  {
    pinMode(target_MFC[i], OUTPUT);
    digitalWrite(target_MFC[i], LOW);
    pinMode(distractor_MFC[i], OUTPUT);
    digitalWrite(distractor_MFC[i], LOW);
    pinMode(target_valves[i], OUTPUT);
    digitalWrite(target_valves[i], LOW);
    pinMode(distractor_valves[i], OUTPUT);
    digitalWrite(distractor_valves[i], LOW);
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
  pinMode(SDA_pin, INPUT_PULLUP);
  pinMode(SCL_pin, INPUT_PULLUP);
  Wire.begin();

  // fill buffers with -1s
  for (i = 0; i < 255; i++)
  {
    stimulus_position_array[i] = -1;
    //distractor_position_array[i] = -1;
  }

  // fill transfer function
  for (i = 0; i < num_of_locations; i++)
  {
    transfer_function[i] = i;
  }

  // analog read - lever position
  analogReadResolution(12);
  Serial.begin(115200);

  // first call to set up params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
}


void loop()
{
  if (close_loop_mode)
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
    SPIWriter(dac_spi_pin, lever_position);
    //----------------------------------------------------------------------------

    //----------------------------------------------------------------------------
    // 2) convert lever position to stimuli given current target zone definition
    //----------------------------------------------------------------------------
    // stimulus_state[1] = LeverToStimulus.WhichZone(1, lever_position);
    motor_location = map(lever_position, 0, 65534, 0, num_of_locations - 1);
    stimulus_state[1] = transfer_function[motor_location];

    // in reward zone or not : if in, odor location ranges between 17 and 48
    for (i = 0; i < 2; i++)
    {
      in_target_zone[i] = (lever_position == constrain(lever_position, target_params[2], target_params[0]));
      //in_target_zone[i] = (stimulus_state[i] == constrain(stimulus_state[i], motor_zone_limits[2], motor_zone_limits[3]));
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
        in_fake_target_zone[i] =
          (fake_stimulus_state[i] == constrain(fake_stimulus_state[i], motor_zone_limits[2], motor_zone_limits[3]));
      }
    }
    //----------------------------------------------------------------------------
  }
  else // open loop mode
  {
    //----------------------------------------------------------------------------
    // 1,2) convert the current entry in TF array to lever position and send to DAC
    //----------------------------------------------------------------------------
    motor_location = transfer_function[transfer_function_pointer];
    lever_position = map(motor_location, 0, num_of_locations - 1, 0, 65534);
    stimulus_state[1] = motor_location;
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
      if (!decouple_reward_and_stimulus)
      {
        if (in_target_zone[1])
        { // currently in reward zone
          if (reward_state == 1 & trialstate[0] == 4)
          { // just entered reward zone
            reward_zone_timestamp = micros();
            reward_state = 2;
          }
        }
        else if (trialstate[0] == 4)
        {
          reward_state = 1; // exited reward zone
        }
      }
      // put new stimulus states into the rolling array
      //stimulus_state_timestamp_array[stimulus_writepointer] = stimulus_state_timestamp;
      //distractor_timestamp_array[distractor_writepointer] = stimulus_state_timestamp;
      //stimulus_position_array[stimulus_writepointer] = stimulus_state[1];
      //distractor_position_array[distractor_writepointer] = stimulus_state[1];
      // roll over write pointers by +1
      //stimulus_writepointer = (stimulus_writepointer + 1) % 255;
      //distractor_writepointer = (distractor_writepointer + 1) % 255;

      // update stimulus state
      stimulus_state[0] = stimulus_state[1];
      if (!close_loop_mode)
      {
        // roll over the TF array pointer
        transfer_function_pointer = (transfer_function_pointer + 1) % (num_of_locations - 1);
        SPIWriter(dac_spi_pin, 600*motor_location);
      }

      // execute stimulus, if needed
      // call Motor1 Arduino
      if (!motor_override)
      {
        //I2Cwriter(motor1_i2c_address, 10 + stimulus_position_array[stimulus_readpointer]);
        I2Cwriter(motor1_i2c_address, 10 + stimulus_state[1]);
        //stimulus_state_timestamp_array[stimulus_readpointer] = 0;
        //stimulus_position_array[stimulus_readpointer] = -1;
        // roll over the read pointer by +1
        //stimulus_readpointer = (stimulus_readpointer + 1) % 255;
        // I2Cwriter(motor1_i2c_address, 10 + stimulus_state[1]);
      }
    }
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 4) process the 'fake target' when reward is decoupled from stimulus
  //----------------------------------------------------------------------------
  if ( (decouple_reward_and_stimulus) & (fake_stimulus_state[1] != fake_stimulus_state[0]) )
  {
    if ( ((micros() - fake_stimulus_state_timestamp) >= 1000 * min_time_since_last_motor_call) )
    {
      fake_stimulus_state_timestamp = micros(); // valid event
      if (in_fake_target_zone[1])
      { // currently in reward zone
        if (reward_state == 1 & trialstate[0] == 4)
        { // just entered reward zone
          reward_zone_timestamp = micros();
          reward_state = 2;
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
  // 5) deliver stimulus, taking into account the user-set delays
  //----------------------------------------------------------------------------
  //if (micros() - stimulus_state_timestamp_array[stimulus_readpointer] > 1000 * delay_feedback_by)
  //{
  //    // call Motor1 Arduino
  //    if (!motor_override)
  //    {
  //      //SPIWriter(dac_spi_pin, 600*stimulus_position_array[stimulus_readpointer]);
  //      //I2Cwriter(motor1_i2c_address, 10 + stimulus_position_array[stimulus_readpointer]);
  //      if (!close_loop_mode)
  //      {
  //        
  //      }
  //    }
  //    //stimulus_state_timestamp_array[stimulus_readpointer] = 0;
  //    //stimulus_position_array[stimulus_readpointer] = -1;
  //    // roll over the read pointer by +1
  //    stimulus_readpointer = (stimulus_readpointer + 1) % 255;
  //  //}
  //}
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 6) deliver distractor stimulus, if needed
  //----------------------------------------------------------------------------
//  if (distractor)
//  {
//    if (micros() - distractor_timestamp_array[distractor_readpointer] > 1000 * delay_distractor_by)
//    {
//      if (distractor_position_array[distractor_readpointer] != -1)
//      {
//        // call Motor2 Arduino
//        if (!motor_override)
//        {
//          //I2Cwriter(motor2_i2c_address, 10 + distractor_position_array[distractor_readpointer]);
//        }
//        distractor_timestamp_array[distractor_readpointer] = 0;
//        distractor_position_array[distractor_readpointer] = -1;
//        // roll over the read pointer by +1
//        distractor_readpointer = (distractor_readpointer + 1) % 255;
//      }
//    }
//  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 7) manage reward
  //----------------------------------------------------------------------------
  // create an override for direct control
  if (reward_override > 0)
  {
    reward_state = 3;
    if (reward_override == 1) // only do this on first call after reward override
    {
      reward_on_timestamp = reward_override_timestamp;
      reward_override = 4;
      digitalWrite(reward_valve_pin, HIGH);
    }
    if (reward_override == 2) // only do this on first call after reward override
    {
      reward_on_timestamp = micros();
      reward_override = 3;
      digitalWrite(reward_valve_pin, HIGH);
    }
    if (reward_override == 2) // only do this on first call after reward override
    {
      reward_on_timestamp = micros();
    }
  }
  if (reward_state == 2 & (micros() - reward_zone_timestamp) > 1000 * reward_params[0])
  {
    reward_state = 3; // flag reward valve opening
    reward_on_timestamp = micros();
    digitalWrite(reward_valve_pin, HIGH);
    digitalWrite(reward_reporter_pin, HIGH);
  }
  if (reward_state == 3 & (micros() - reward_on_timestamp) > 1000 * reward_params[1])
  {
    digitalWrite(reward_valve_pin, LOW);
    digitalWrite(reward_reporter_pin, LOW);
    reward_state = 0;
    reward_override = 0;
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 8) manage reporter pins, valves etc based on time elapsed since last event
  //----------------------------------------------------------------------------
  digitalWrite(target_valves[0], (target_valve_state || (trialstate[0] == 4)) ); // open odor valve
  digitalWrite(target_valves[1], (target_valve_state || (trialstate[0] == 4)) ); // open air valve
  digitalWrite(trial_reporter_pin, (trialstate[0] == 4)); // active trial?
  digitalWrite(in_target_zone_reporter_pin, in_target_zone[1]); // in_target_zone?
  digitalWrite(in_reward_zone_reporter_pin, (reward_state == 2)); // in_reward_zone?
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 6) determine trial mode
  //----------------------------------------------------------------------------
  trialstate[1] = trialstates.WhichState(trialstate[0], lever_position, (micros() - trial_timestamp));
  if (trialstate[1] != trialstate[0])
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
  if (Serial.available() > 0)
  {
    FSMheader = Serial.read();
    switch (round(10 * (FSMheader / 10))) // just a hack to parse out cases into categories
    {
      case 10: // opening/closing handshake
        //Serial.write(5);
        switch (FSMheader - 10)
          {
            case 0: // opening handshake
              Serial.write(5);
              //stimulus_writepointer = 0;
              //timer_override = true;
              break;
            case 1: // closing handshake
              Serial.write(6);
              //timer_override = false;
              break;
          }
        break;
      case 20: // update variables
        serial_clock = millis();
        while ( Serial.available() < 2 && (millis() - serial_clock) < 1000 )
        { } // wait for serial input or time-out
        if (Serial.available() < 2)
        {
          SerialIntWriter(-1);
        }
        else
        {
          num_of_params = SerialIntReader(); // get number of params to be updated
          i = 0;
          while (i < num_of_params)
          {
            while ((Serial.available() < 2))
            { }
            if (Serial.available() >  1)
            {
              param_value = SerialIntReader();
              SerialIntWriter(param_value);
              param_array[i] = param_value;
              i = i + 1;
            }
            else
            {
              SerialIntWriter(99);
            }
          }
          UpdateAllParams(); // parse param array to variable names and update motor params
        }
        break;
      case 30: // update transfer function or calibrate transfer function
        serial_clock = millis();
        while ( Serial.available() < 2 && (millis() - serial_clock) < 1000 )
        { } // wait for serial input or time-out
        if (Serial.available() < 2)
        {
          SerialIntWriter(-1);
        }
        else
        {
          i = 0;
          switch (FSMheader - 30)
          {
            case 0: // close loop
              num_of_locations = SerialIntReader(); // get number of params to be updated
              min_time_since_last_motor_call = min_time_since_last_motor_call_default;
              close_loop_mode = 1;
              break;
            case 1: // open loop
              num_of_locations = num_of_locations;
              min_time_since_last_motor_call = SerialIntReader();
              close_loop_mode = 0;
              break;
          }
          while (i < num_of_locations)
          {
            while ((Serial.available() < 2))
            { }
            if (Serial.available() >  1)
            {
              transfer_function[i] = SerialIntReader();
              SerialIntWriter(transfer_function[i]);
              i = i + 1;
            }
            else
            {
              SerialIntWriter(93);
            }
          }
          SerialIntWriter(83);
          transfer_function_pointer = 0;
        }
        break;
      case 40: // toggle MFCs or odor valves
        switch (FSMheader - 40)
        {
          case 0: // MFCs OFF
            for (i = 0; i < 2; i++)
            {
              digitalWrite(target_MFC[i], LOW);
            }
            break;
          case 1: // MFCs ON
            for (i = 0; i < 2; i++)
            {
              digitalWrite(target_MFC[i], HIGH);
            }
            break;
          case 2: // MFCs OFF
            for (i = 0; i < 2; i++)
            {
              digitalWrite(distractor_MFC[i], LOW);
            }
            break;
          case 3: // MFCs ON
            for (i = 0; i < 2; i++)
            {
              digitalWrite(distractor_MFC[i], HIGH);
            }
            break;
          case 4: // target valves
            target_valve_state = !target_valve_state;
            break;
          case 5: // distractor valves
            distractor_valve_state = !distractor_valve_state;
            break;
        }
        break;
      case 50: // update motor variables
        serial_clock = millis();
        while ( Serial.available() < 2 && (millis() - serial_clock) < 1000 )
        { } // wait for serial input or time-out
        if (Serial.available() < 2)
        {
          SerialIntWriter(-1);
        }
        else
        {
          num_of_params = SerialIntReader(); // get number of params to be updated
          i = 0;
          while (i < num_of_params)
          {
            while ((Serial.available() < 2))
            { }
            if (Serial.available() >  1)
            {
              param_value = SerialIntReader();
              SerialIntWriter(param_value);
              motor_zone_limits[i] = param_value;
              i = i + 1;
            }
            else
            {
              SerialIntWriter(99);
            }
          }
          UpdateMotorParams(); // parse param array to variable names and update motor params
        }
        break;
      case 60: // motor related
        I2Cwriter(motor1_i2c_address, 1);
        switch (FSMheader - 60)
        {
          case 0: // disable override
            motor_override = false;
            break;
          case 1: // center the motor
            motor_override = true;
            I2Cwriter(motor1_i2c_address, 1); // enable motors
//            if (distractor)
//            {
//              I2Cwriter(motor2_i2c_address, 1);
//            }
            delay(10);
            I2Cwriter(motor1_i2c_address, (motor_zone_limits[1] + (motor_zone_limits[3] - motor_zone_limits[2]) / 2) ); // move to target
//            if (distractor)
//            {
//              I2Cwriter(motor2_i2c_address, (motor_zone_limits[1] + (motor_zone_limits[3] - motor_zone_limits[2]) / 2) );
//            }
            break;
          case 2:
            motor_override = true;
            I2Cwriter(motor1_i2c_address, 1);  // enable motors
//            if (distractor)
//            {
//              I2Cwriter(motor2_i2c_address, 1);
//            }
            delay(10);
            I2Cwriter(motor1_i2c_address, 0); // move to target
//            if (distractor)
//            {
//              I2Cwriter(motor2_i2c_address, 0);
//            }
            break;
        }
        break;
      case 70: // motor related
        I2Cwriter(motor1_i2c_address, int(FSMheader - 70));
//        if (distractor)
//        {
//          I2Cwriter(motor2_i2c_address, int(FSMheader - 70));
//        }
        break;
      case 80: // reward valve related
        switch (FSMheader - 80)
        {
          case 0: // close reward valve
            reward_override = 0;
            break;
          case 1: // open reward valve
            reward_override = 1;
            reward_override_timestamp = micros();
            break;
          case 2: // open reward valve for reward valve duration
            reward_override = 1;
            reward_override_timestamp = micros();
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
  }
  //----------------------------------------------------------------------------

} // end of loop()

int SerialIntReader ()
{
  int UpdatedVariable = 0;
  byte inByte1 = Serial.read();
  byte inByte2 = Serial.read();
  UpdatedVariable = (int)word(inByte2, inByte1);
  return UpdatedVariable;
}

void SerialIntWriter (int VariableToWrite)
{
  Serial.write(lowByte(VariableToWrite));
  Serial.write(highByte(VariableToWrite));
}

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
  SerialIntWriter(89);
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
  // params[19-21] = stage, transfer function locations, steepness
  target_on = (param_array[22] > 0);
  delay_feedback_by = ((int)target_on) * (param_array[22] - 1);
  //distractor = (param_array[23] > 0);
  //delay_distractor_by = ((int)distractor) * (param_array[23] - 1);
  for (i = 0; i < 3; i++)
  {
    fake_target_params[i] = param_array[24 + i]; // high lim, target, low lim
  }
  decouple_reward_and_stimulus = (fake_target_params[1] > 0);

  // update motor targets
  // LeverToStimulus.UpdateTargetParams(target_params, fake_target_params, trial_trigger_level[1]);

  // update trial state params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
}

void UpdateMotorParams()
{
  SerialIntWriter(89);
  // LeverToStimulus.UpdateLocations(motor_zone_limits);
}
