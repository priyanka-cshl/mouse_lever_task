// ---- adding libraries ------------------------------------------------------
#include <SPI.h> // library for SPI communication - to DAC
#include "trialstates.h" // function to process trial states
#include <Wire.h> // library for I2C communication - to slave Arduinos
#include <DueTimer.h> // Import the ArCOM library
#include "ArCOM.h"
// ----------------------------------------------------------------------------

// ---- initialize function calls ---------------------------------------------
trialstates trialstates;
ArCOM myUSB(SerialUSB); // Create an ArCOM wrapper for the SerialUSB interface
// ----------------------------------------------------------------------------

//pins
int lever_in = A0; // 
int fake_lever_in = A8; // signal generator

int trial_reporter_pin = 41;
int in_target_zone_reporter_pin = 43;
int in_reward_zone_reporter_pin = 45;
int reward_reporter_pin = 47;
int reward_valve_pin = 8;
int target_valves[] = {9, 10};
int odor_valves[] = {37, 31, 33, 35};

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
int close_loop_mode = 1; // motor moves in sync with lever/analog signal
int fake_lever = 0;

//variables : stimulus related
int stimulus_state[] = {0, 0}; // old, new
long stimulus_state_timestamp = micros();
bool in_target_zone[2] = {false, false};
bool timer_override = false; // to disable timer start after serial communication
int training_stage = 2;

// MFC related and valves related
int which_odor = 0;
bool odor_ON = true;
bool target_valve_state[2] = {false, false};

//variables : motor and transfer function related
bool motor_override = false;
const int min_time_since_last_motor_call_default = 10; // in ms
int min_time_since_last_motor_call = 10; // in ms - timer period
unsigned int num_of_locations = 100;
unsigned short transfer_function[99] = {0}; // ArCOM aray needs unsigned shorts
int motor_location = 1;
int transfer_function_pointer = 0; // for transfer function calibration
unsigned int my_location = 101;
unsigned int left_first = 1;
int rewarded_locations[2] = {101, 101};

//variables : reward related
int reward_state = 0;
long reward_zone_timestamp = micros();
long trial_off_buffer = 0;
int reward_params[] = {100, 40, 0}; // {hold for, duration, summed hold for} in ms
unsigned short multi_reward_params[] = {200, 10}; // {hold for, duration} in ms for the subsequent rewards within a trial
int multiplerewards = 0; // only one reward per trial
long time_in_target_zone = 0;

//variables : perturbation related - water delivery decoupled from stimulus
bool decouple_reward_and_stimulus = false;

//variables : trial related
int trialstate[] = {0, 0}; // old, new
long trial_timestamp = micros();
long trial_trigger_level[] = {52000, 13000}; // trigger On, trigger Off
int trial_trigger_timing[] = {10, 600, 3000}; // trigger hold, trigger smooth, trial min, trial max
int long_iti = 0;
int normal_iti = 0;

//variables : general
int i = 0;
int check = 0;

//variables : serial communication
long serial_clock = micros();
int FSMheader = 0;
unsigned int num_of_params = 30;
unsigned short param_array[30] = {0}; // ArCOM aray needs unsigned shorts

// variables - camera sync
int camera_pin = 29;
bool camera = 0;
int camera_on = 0;

// variables - cleaning
bool odorON = false;
byte whichOdor = 0;
bool cleaningON = false;

void setup()
{
  SerialUSB.begin(115200);

  for (i = 0; i < 2; i++)
  {
    pinMode(target_valves[i], OUTPUT);
    digitalWrite(target_valves[i], LOW);
  }

  for (i = 0; i < 4; i++)
  {
    pinMode(odor_valves[i], OUTPUT);
    digitalWrite(odor_valves[i], LOW);
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
}


void loop()
{
  //----------------------------------------------------------------------------
  // 1) process the incoming lever position data - and resend to DAC
  //----------------------------------------------------------------------------
  // read lever position as analog val
  if (fake_lever==0)
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
    SPIWriter(dac_spi_pin, 300 * (motor_location));
    //----------------------------------------------------------------------------
    // 1,2) convert the current entry in TF array to lever position and send to DAC
    //----------------------------------------------------------------------------
    motor_location = transfer_function[transfer_function_pointer];
    stimulus_state[1] = motor_location;
  }

  // in reward zone or not : if in, odor location ranges between 17 and 48
  for (i = 0; i < 2; i++)
  {
    if (decouple_reward_and_stimulus)
    {
      in_target_zone[i] = (lever_position == constrain(lever_position, fake_target_params[2], fake_target_params[0]));
    }
    else
    {
      in_target_zone[i] = (stimulus_state[1] == constrain(stimulus_state[1], rewarded_locations[0], rewarded_locations[1]));
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
      if (trialstate[0] == 4)
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
          time_in_target_zone = time_in_target_zone + (reward_zone_timestamp - micros());
        }
        if (multiplerewards > 0)
        {
          if ( in_target_zone[1] && ((reward_state == 4)||(reward_state == 7)) && (micros() - reward_zone_timestamp)<= 1000*multiplerewards )
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

  //----------------------------------------------------------------------------
  // 4) manage reward
  //----------------------------------------------------------------------------
  if (reward_state == 2 && ((micros() - reward_zone_timestamp) > 1000 * reward_params[0]))
  {
    reward_state = 3; // flag reward valve opening
    time_in_target_zone = 0; // reset timespent value
    trialstates.UpdateITI(normal_iti); // don't impose any ITI
    Timer4.start(1000 * reward_params[1]); // call reward timer
  }
  if (reward_state == 5 && ((micros() - reward_zone_timestamp) > 1000 * multi_reward_params[0]))
  {
    reward_state = 6; // flag reward valve opening
    Timer4.start(1000 * multi_reward_params[1]); // call reward timer
  }
  if ( trialstate[0] == 4 && (time_in_target_zone > 1000 * reward_params[2]) )
  {
    reward_state = 3; // flag reward valve opening
    time_in_target_zone = 0; // reset timespent value
    Timer4.start(1000 * reward_params[1]); // call reward timer
  }
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 5) manage reporter pins, valves etc based on time elapsed since last event
  //----------------------------------------------------------------------------
  if (!cleaningON)
  {
    digitalWrite(target_valves[0], (target_valve_state[0] || (trialstate[0] != 0) || !close_loop_mode) ); // open odor valve
    digitalWrite(target_valves[1], (target_valve_state[1] || (trialstate[0] != 0) || !close_loop_mode) ); // open air valve
  }

  digitalWrite(trial_reporter_pin, (trialstate[0] == 4)); // active trial?
  digitalWrite(in_target_zone_reporter_pin, in_target_zone[1]); // in_target_zone?
  digitalWrite(in_reward_zone_reporter_pin, (reward_state == 2)||(reward_state == 5)); // in_reward_zone?
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
    // if trialstate is active and reward has been received 
    // - trialstate should be pushed to 0 after a buffer time has elapsed
    // buffer time = multi_reward_params[0] if multiplerewards==0
    // buffer time = multiplerewards if multiplerewards!=0
    // note: reward_zone_timestamp will be updated when reward valve is turned off
    if ( trialstate[0]==4 && ( (reward_state==4)||(reward_state==7) ) && (micros() - reward_zone_timestamp)>trial_off_buffer)
    {
      trialstate[1] = 0;
    }
    else
    {
      trialstate[1] = trialstates.WhichState(trialstate[0], lever_position, (micros() - trial_timestamp));
    }
  }
  if (trialstate[1] != trialstate[0]) // trial state changes
  {
    reward_state = (int)(trialstate[1] == 4); // trial was just activated, rewards can be triggered now
    trial_timestamp = micros();
    time_in_target_zone = 0; // reset timespent value
    // manage odor valves
    if (timer_override)
    {
      if ( (trialstate[1]==0) && odor_ON)
      {
        for (i=0; i<4; i++)
        {
          digitalWrite(odor_valves[i],(i==trialstate[1]));
          odor_ON = false;
        }
      }
      else if ( (trialstate[1]==1) && (trialstate[0]==0) )
      {
        for (i=0; i<4; i++)
        {
          digitalWrite(odor_valves[i],(i==which_odor));
        }
      }
      else if (trialstate[1]==2)
      {
        odor_ON = true;
        // reset long ITI
        trialstates.UpdateITI(long_iti); // will be changed to zero if animal receives a reward in the upcoming trial
      }
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
            camera_on = 1;
            break;
          case 1: // Acquisition start handshake
            myUSB.writeUint16(6);
            // fill stimulus position array
            stimulus_state[0] = 20;
            stimulus_state[1] = 20;

            digitalWrite(odor_valves[0],HIGH);
            odor_ON = true;
            timer_override = true;
            camera_on = 1;
            break;
          case 2: // Acquisition stop handshake
            myUSB.writeUint16(7);
            timer_override = false;
            // turn off all odor valves as caution
            for (i=0; i<4; i++)
            {
              digitalWrite(odor_valves[i],LOW);
            }
            camera_on = 1;
            break;
          case 3: // Cleaning Routine start
            myUSB.writeUint16(3);
            odorON = false;
            timer_override = false;
            camera_on = 1;
            cleaningON = true;
            Timer5.start(1000*1000);
            break;
          case 4: // Cleaning Routine stop
            myUSB.writeUint16(4);
            timer_override = false;
            // turn off all odor valves as caution
            for (i=0; i<4; i++)
            {
              digitalWrite(odor_valves[i],LOW);
            }
            camera_on = 1;
            cleaningON = false;
            Timer5.stop();
            break;            
        }
        break;
      case 20: // update variables
          num_of_params = myUSB.readUint16(); // get number of params to be updated
          myUSB.readUint16Array(param_array, num_of_params);
          myUSB.writeUint16Array(param_array, num_of_params);
          UpdateAllParams(); // parse param array to variable names and update motor params
        break;
      case 30: // update transfer function or calibrate transfer function
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
          myUSB.writeUint16(83);
          transfer_function_pointer = 0;
        break;
      case 40: // toggle MFCs or odor valves
        switch (FSMheader - 40)
        {
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
            serial_clock = millis();
            while ( myUSB.available() < 2 && (millis() - serial_clock) < 1000 )
            { } // wait for serial input or time-out
            myUSB.readUint16Array(multi_reward_params, 2);
            myUSB.writeUint16Array(multi_reward_params, 2);
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
  // parse param array to variable names
  // param_array[0-1] : [sample_rate refresh_rate]

  lever_rescale_params[0] = param_array[2]; // gain, offset
  lever_rescale_params[1] = param_array[3];
  reward_params[0] = param_array[4];
  reward_params[1] = param_array[5];
  reward_params[2] = param_array[15]; // originally target_which, now summed hold duration
  // param_array[6-7] : [rewards_per_block perturb_probability]
  trial_trigger_level[0] = param_array[8];
  trial_trigger_level[1] = param_array[9];
  for (i = 0; i < 3; i++)
  {
    trial_trigger_timing[i] = param_array[10 + i]; // trig_hold, min_trial, max_trial
  }
  
  // copy trig_smooth to multiplerewards
  multiplerewards = param_array[13];

  if (multiplerewards == 0)
  {
    trial_off_buffer = 1000*param_array[0];
  }
  else
  {
    trial_off_buffer = 1000*multiplerewards;
  }

  camera_on = param_array[1];
  
  // param[14] = timestamp
  which_odor = param_array[14]; // odor vial number
  //target_which = param_array[15];
  //for (i = 0; i < 3; i++)
  //{
  //  target_params[i] = param_array[16 + i]; // high lim, target, low lim
  //}
  // params[19-21] = 'target_locations' 'skip_locations' 'offtarget_locations'
  rewarded_locations[0] = 101 - param_array[19];
  rewarded_locations[1] = 101 + param_array[19];
  //target_on = (param_array[22] > 0);
  long_iti = param_array[22];
  //delay_feedback_by = ((int)target_on) * (param_array[22] - 1) / min_time_since_last_motor_call;
  for (i = 0; i < 3; i++)
  {
    fake_target_params[i] = param_array[24 + i]; // high lim, target, low lim
  }
  decouple_reward_and_stimulus = (fake_target_params[1] > 0);
  //param_array[27] = TF size;
  training_stage = param_array[28];
  fake_lever = param_array[29];
  
  // update trial state params
  trialstates.UpdateTrialParams(trial_trigger_level, trial_trigger_timing);
}

void MoveMotor()
{
  if (!motor_override)// && (trialstate[1] == 4))
  {
    I2Cwriter(motor1_i2c_address, 10 + stimulus_state[1]);
  }

  if (!close_loop_mode)
  {
    // roll over the TF array pointer
    transfer_function_pointer = (transfer_function_pointer + 1) % num_of_locations;
  }
    camera = camera_on*(!camera);
    digitalWrite(camera_pin,camera);
}

void RewardNow()
{
  if ( ((reward_state == 3)||(reward_state == 6)) && timer_override )
  {
    digitalWrite(reward_valve_pin, HIGH);
    digitalWrite(reward_reporter_pin, HIGH);
    reward_state = reward_state + 1;
    reward_zone_timestamp = micros();
  }
  else
  {
    Timer4.stop();
    digitalWrite(reward_valve_pin, LOW);
    digitalWrite(reward_reporter_pin, LOW);
  }
}

void CleaningRoutine()
{
  // odorON = true,false; whichOdor = 0,1,2,3;
  odorON = !odorON; // toggle the state of the final valves
  digitalWrite(target_valves[0], odorON );
  digitalWrite(target_valves[1], odorON );
  if (odorON)
  {
    // update the odor vial index
    whichOdor = (whichOdor + 1)%4;
    // update valve state
    for (i=0; i<4; i++)
    {
      digitalWrite(odor_valves[i],(i==whichOdor));
    }
  }
}

