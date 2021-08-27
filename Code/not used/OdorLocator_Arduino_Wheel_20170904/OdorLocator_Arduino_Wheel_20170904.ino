// ---- adding libraries ------------------------------------------------------
#include <SPI.h> // library for SPI communication - to DAC
#include <Wire.h> // library for I2C communication - to slave Arduinos
#include <DueTimer.h> 
#include "ArCOM.h" // Import the ArCOM library
#include <Encoder.h>
// ----------------------------------------------------------------------------

// ======= PINS ================================
// Inputs
int rotary_encoder_A = 11; // rotary encoder
int rotary_encoder_B = 12; // rotary encoder

// Outputs
const byte SDA_pin = 20; // spi DAC
const byte SCL_pin = 21; // spi DAC
int dac_spi_pin = 22; // to 16-bit DAC
int reward_valve_pin = 8;
int target_valves[] = {9, 10};
int odor_valves[] = {37, 31, 33, 35};
int trial_reporter_pin = 41;
int in_target_zone_reporter_pin = 43;
int in_reward_zone_reporter_pin = 45;
int reward_reporter_pin = 47;
// ------- PINS --------------------------------

// ======= Function calls and communication =====
Encoder RotaryEncoder(rotary_encoder_A, rotary_encoder_B);
int motor1_i2c_address = 7; // I2C call to Motor Arduino
ArCOM myUSB(SerialUSB); // Create an ArCOM wrapper for the SerialUSB interface
// ------- Function calls and communication -----

// ======= Variables ============================
// Wheel position
int rotary_position_in = 0; 
long rotary_position_out = 0L;
// Motor control
int odorlocations_per_side = 100;
unsigned int my_location = odorlocations_per_side; //101;
int rewarded_locations[2] = {my_location, my_location};
bool timer_override = false; // to disable motor timer start after serial communication
bool motor_override = false; // to disable I2C write to motor arduino for direct motor controls
const int min_time_since_last_motor_call_default = 10; // in ms
int min_time_since_last_motor_call = 10; // in ms - timer period
int motor_location = 1;
int fake_motor_location = 1;
int motor_start = 0; // or 2*odorlocations_per_side
// Transfer function
int which_TF = 1;
int which_fake_TF = 1;
bool left_first = true;
int probability_left = 1;
unsigned int num_of_TFs = 12;
unsigned short corridor_lengths[11] = {0}; // ArCOM aray needs unsigned shorts
// Odor stimulus
int which_odor = 0;
bool odor_ON = true;
bool target_valve_state[2] = {false, false};
bool cleaningON = false; // variables - cleaning
bool odorON = false; 
// Reward
int reward_params[] = {100, 40}; // {hold for, duration} in ms
unsigned short multi_reward_params[] = {200, 10}; // {hold for, duration} in ms for the subsequent rewards within a trial
int multiplerewards = 0; // only one reward per trial
// Trial
int trial_trigger_timing[] = {10, 20, 600, 3000}; // trial off, trial armed, trial max, trial_off_buffer
long trial_off_buffer = 0;
// Camera sync
int camera_pin = 29;
bool camera = 0;
int camera_on = 0;
// State variables
int stimulus_state[] = {0, 0}; // {old, new} 
long stimulus_state_timestamp = micros();
bool in_target_zone = false;
int trialstate[] = {0, 0}; // old, new
long trial_timestamp = micros();
int reward_state = 0;
long reward_zone_timestamp = micros();
int i = 0;
// Perturbations
int close_loop_mode = 1; // motor moves in sync with lever/analog signal
int fake_lever = 0;
bool decouple_reward_and_stimulus = false;
int training_stage = 2;
// Serial communication
long serial_clock = micros();
int FSMheader = 0;
unsigned int num_of_params = 30;
unsigned short param_array[30] = {0}; // ArCOM aray needs unsigned shorts
// ------- Variables ----------------------------

void setup()
{
  // set up communications
  SerialUSB.begin(115200); // Arcom communication
  pinMode (dac_spi_pin, OUTPUT); // SPI
  SPI.begin(dac_spi_pin);
  Wire.begin(); // I2C
  
  // Output lines - valves and reporter pins
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

  // fill corridor_lengths array
  for (i = 0; i < num_of_TFs; i++)
  {
    corridor_lengths[i] = 20;
  }

  // Timers
  Timer3.attachInterrupt(MoveMotor); // Timer for motor update
  Timer3.start(1000 * min_time_since_last_motor_call_default); // Calls every 10 msec
  Timer4.attachInterrupt(RewardNow); // Timer for reward delivery  
  Timer5.attachInterrupt(CleaningRoutine); // Timer for odor machine cleaning
  
  // analog read - lever position
  analogReadResolution(12);
}

void loop()
{
  //----------------------------------------------------------------------------
  // 1) read current wheel position - scale and resend to DAC
  //----------------------------------------------------------------------------
  if (fake_lever==0) // read the wheel position from the rotary encoder
  {
    rotary_position_in = RotaryEncoder.read();
  }
  else // read a secondary analog signal
  {
    rotary_position_in = analogRead(fake_lever_in); 
  }
  // remap from 12-bit to 16-bit and rescale (if needed)
  rotary_position_in = constrain(rotary_position_in, 0, 4095); // displacement < 4 turns from start
  rotary_position_out = map(rotary_position_in, 0, 4095, 0, 65534); 
  //----------------------------------------------------------------------------

  if (trialstate[0] == 2) // Trial is On
  {
    //----------------------------------------------------------------------------
    // 2) convert wheel position to stimuli given current target zone definition
    // and write wheel position to DAC or roll through motor positions and write
    // motor position to DAC
    //----------------------------------------------------------------------------
    if (close_loop_mode)
    {
      if (left_first)
      {
        motor_location = map(rotary_position_in, 0, 2*corridor_lengths[which_TF], 0, 2*odorlocations_per_side);  
      }
      else
      {
        motor_location = map(rotary_position_in, 0, 2*corridor_lengths[which_TF], 2*odorlocations_per_side, 0);
      }
      fake_motor_location = map(rotary_position_in, 0, 2*corridor_lengths[which_fake_TF], 0, 2*odorlocations_per_side);
      SPIWriter(dac_spi_pin, rotary_position_out);
    }
    else
    {
      SPIWriter(dac_spi_pin, 300 * (motor_location));
    }
    //----------------------------------------------------------------------------

    //----------------------------------------------------------------------------
    // 3) update stimulus state, direction etc. if the stimulus_state has changed
    //----------------------------------------------------------------------------
    // in reward zone or not
    if (decouple_reward_and_stimulus)
    {
      in_target_zone = (fake_motor_location == constrain(fake_motor_location, rewarded_locations[0], rewarded_locations[1]));
      stimulus_state[1] = fake_motor_location;
    }
    else
    {
      in_target_zone = (motor_location == constrain(motor_location, rewarded_locations[0], rewarded_locations[1]));
      stimulus_state[1] = motor_location;
    }

    // has the stimulus state changed?
    if (stimulus_state[1] != stimulus_state[0])
    {
      if ((micros() - stimulus_state_timestamp) >= 1000 * min_time_since_last_motor_call) 
      {
        stimulus_state_timestamp = micros(); // valid event
        // update reward zone time stamp, if needed
        if (in_target_zone && (reward_state == 1)) // in trial, entered target zone, and has not received reward in this trial
        {
          reward_zone_timestamp = micros();
          reward_state = 2;
        }
        if (!in_target_zone && (reward_state == 2)) // exited reward zone before getting a reward, retrigger reward availability
        {
          reward_state = 1; 
        }
        if (multiplerewards > 0)
        {
          if (in_target_zone && ((reward_state == 4)||(reward_state == 7)) && (micros() - reward_zone_timestamp)<= 1000*multiplerewards )
          {
            reward_zone_timestamp = micros();
            reward_state = 5;
          }
          if (!in_target_zone && (reward_state == 5))
          {
            reward_state = 4; // was in reward zone in this trial, but exited reward zone before getting a reward, retrigger reward availability
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
      Timer4.start(1000 * reward_params[1]); // call reward timer
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
  if (!cleaningON)
  {
    digitalWrite(target_valves[0], (target_valve_state[0] || (trialstate[0] == 2) || !close_loop_mode) ); // open odor valve
    digitalWrite(target_valves[1], (target_valve_state[1] || (trialstate[0] == 2) || !close_loop_mode) ); // open air valve
  }
  digitalWrite(trial_reporter_pin, (trialstate[0] == 2)); // active trial?
  digitalWrite(in_target_zone_reporter_pin, in_target_zone); // in_target_zone?
  digitalWrite(in_reward_zone_reporter_pin, (reward_state == 2)||(reward_state == 5)); // in_reward_zone?
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 6) determine trial mode
  //----------------------------------------------------------------------------
  if ( (trialstate[0] == 0) && ((micros() - trial_timestamp)> 1000 * trial_trigger_timing[0]) )
  {
    trialstate[1] = 1; // arm trial
    // turn on odor valves
    trial_timestamp = micros();
  }
  if ( (trialstate[0] == 1) && ((micros() - trial_timestamp)> 1000 * trial_trigger_timing[1]) )
  {
    trialstate[1] = 2; // activate trial
    reward_state = 1; // trial was just activated, rewards can be triggered now
    // turn on air/odor flow through the manifold
    trial_timestamp = micros();
  }
  if (trialstate[0] == 2)
  {
    if ( (micros() - trial_timestamp)> 1000 * trial_trigger_timing[2] ) 
    {
      trialstate[1] = 0; // turn off trial
      // turn off odor/air valves
      // recoil motor
      trial_timestamp = micros();
    }
    else if ( (reward_state==4)||(reward_state==7) && (micros() - reward_zone_timestamp)>trial_off_buffer) 
    // if trialstate is active and reward has been received 
    // - trialstate should be pushed to 0 after a buffer time has elapsed
    // buffer time = multi_reward_params[0] if multiplerewards==0
    // buffer time = multiplerewards if multiplerewards!=0
    // note: reward_zone_timestamp will be updated when reward valve is turned off
    {
      trialstate[1] = 0;
    }
  }

  if (trialstate[1] != trialstate[0]) // trial state changed
  {
    // manage odor valves
    if (timer_override)
    {
      if (trialstate[1]==0)
      {
        if (odor_ON)
        { for (i=0; i<4; i++)
          {
            digitalWrite(odor_valves[i],(i==trialstate[1]));
            odor_ON = false;
          }
        }
        // decide whether next trial will be approach from left or right
        left_first = (random(99)<probability_left);
        motor_start = ((int)!left_first)*2*odorlocations_per_side;
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
            stimulus_writepointer = 0;
            // fill stimulus position array
            for (i = 0; i < stimulus_array_size; i++)
            {
              stimulus_position_array[i] = 20;
            }
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
        serial_clock = millis();
        while ( myUSB.available() < 2 && (millis() - serial_clock) < 1000 )
        { } // wait for serial input or time-out
        if (myUSB.available() < 2)
        {
          myUSB.writeUint16(1);
        }
        else
        {
          num_of_params = myUSB.readUint16(); // get number of params to be updated
          myUSB.readUint16Array(param_array, num_of_params);
          myUSB.writeUint16Array(param_array, num_of_params);
          UpdateAllParams(); // parse param array to variable names and update motor params
        }
        break;
      case 30: // update corridor corridor_lengths
        serial_clock = millis();
        while ( myUSB.available() < 2 && (millis() - serial_clock) < 10000 )
        { } // wait for serial input or time-out
        if (myUSB.available() < 2)
        {
          myUSB.writeUint16(1);
        }
        else
        {
          switch (FSMheader - 30)
          {
            case 0: // close loop
              num_of_TFs = myUSB.readUint16(); // get number of params to be updated
              min_time_since_last_motor_call = min_time_since_last_motor_call_default;
              close_loop_mode = 1;
              break;
            case 1: // open loop
              num_of_TFs = myUSB.readUint16();
              min_time_since_last_motor_call = myUSB.readUint16();
              close_loop_mode = 0;
              break;
          }
          myUSB.readUint16Array(corridor_lengths, num_of_TFs);
          myUSB.writeUint16Array(corridor_lengths, num_of_TFs);
          myUSB.writeUint16(83);
        }
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

  reward_params[0] = param_array[0]; // target hold time
  reward_params[1] = param_array[1]; // water valve open time
  multiplerewards = param_array[2];

  for (i = 0; i < 4; i++) // param_array[3-6]
  {
    trial_trigger_timing[i] = param_array[3 + i]; // trial off, trial armed, trial max, trial_off_buffer
  }

  if (multiplerewards == 0)
  {
    trial_off_buffer = 1000*trial_trigger_timing[3];
  }
  else
  {
    trial_off_buffer = 1000*multiplerewards;
  }

  multi_reward_params[0] = param_array[7]; // target hold time
  multi_reward_params[1] = param_array[8]; // valve on duration
  camera_on = param_array[9];
  which_odor = param_array[10]; // odor vial number
  rewarded_locations[0] = odorlocations_per_side - param_array[11];
  rewarded_locations[1] = odorlocations_per_side + param_array[11];
  which_TF = param_array[12];
  which_fake_TF = param_array[13];
  probability_left = param_array[14];
  decouple_reward_and_stimulus = (which_fake_TF != which_TF);
  training_stage = param_array[15];
  fake_lever = param_array[16];
}

void MoveMotor() // Timer3 interrupt routine
{
  if ((!motor_override) && (trialstate[1] == 2) && (motor_location != motor_start))
  {
    I2Cwriter(motor1_i2c_address, 10 + motor_location);
  }
  else if (motor_location != motor_start)
  {
    // move motor to start position and wait for trial to be active again
    // do a slow move
    I2Cwriter(motor1_i2c_address, 10 + 3 + (int)left_first); // special code recognized the motor arduino
    motor_location = motor_start;
  }
  if (!close_loop_mode)
  {
    motor_location = (motor_location + 1) % (2*odorlocations_per_side);
  }
  // toggle camera trigger bet'n low and high when syncing videos
  camera = camera_on*(!camera);
  digitalWrite(camera_pin,camera);
}

void RewardNow() // Timer4 interrupt routine
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

void CleaningRoutine() // Timer5 interrupt routine
{
  // odorON = true,false; which_odor = 0,1,2,3;
  odorON = !odorON; // toggle the state of the final valves
  digitalWrite(target_valves[0], odorON );
  digitalWrite(target_valves[1], odorON );
  if (odorON)
  {
    which_odor = (which_odor + 1)%4; // update the odor vial index
    for (i=0; i<4; i++) // update valve state
    {
      digitalWrite(odor_valves[i],(i==which_odor));
    }
  }
}

