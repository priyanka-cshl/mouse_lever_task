// ---- adding libraries ------------------------------------------------------
#include <SPI.h> // library for SPI communication - to DAC
#include <Wire.h> // library for I2C communication - to slave Arduinos
#include <DueTimer.h>
// ----------------------------------------------------------------------------

//pins
int lever_in = A8; // A0-A8, changed briefly to get signal generator IN
int dac_spi_pin = 22;
const byte SDA_pin = 20;
const byte SCL_pin = 21;
int motor1_i2c_address = 7;
//int motor2_i2c_address = 8;
const byte motor_timer_period = 10; // ms

//variables : lever related
long lever_position = 0L;
long lever_rescaled = 0L;
long lever_rescale_params[] = {25000, 13380}; // {gain, offset}
int num_of_locations = 101;
int motor_location = 1;
byte stimulus_position_array[1199] = {0};
const int stimulus_array_size = 1200;
int stimulus_writepointer = 0;
int stimulus_readpointer = 0;
bool motor_override = true;
int stimulus_state[] = {0, 0}; // old, new

//variables : serial communication
long serial_clock = micros();
int FSMheader = 0;
int param_index = 0;
int num_of_params = 5;
int param_array[] = {};
int param_value = 0;
bool timer_override = false; // to disable timer start after serial communication
int delay_feedback_by = 0; // in timer periods (max = 1200)


void setup()
{
  // set up SPI
  pinMode (dac_spi_pin, OUTPUT);
  SPI.begin(dac_spi_pin);

  // set up I2C
  //  pinMode(SDA_pin, INPUT_PULLUP);
  //  pinMode(SCL_pin, INPUT_PULLUP);
  Wire.begin();

  // Timer for motor update
  Timer3.attachInterrupt(MoveMotor);
  Timer3.start(1000*motor_timer_period); // Calls every 10 msec

  // analog read - lever position
  analogReadResolution(12);
  Serial.begin(115200);

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
  SPIWriter(dac_spi_pin, lever_position);
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 2) convert lever position to stimuli given current target zone definition
  //----------------------------------------------------------------------------
  // stimulus_state[1] = LeverToStimulus.WhichZone(1, lever_position);
  motor_location = map(lever_position, 0, 65534, 0, num_of_locations - 1);
  stimulus_state[1] = motor_location;
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  // 7) Serial handshakes to check for parameter updates etc
  //----------------------------------------------------------------------------
  if (Serial.available() > 0)
  {
    FSMheader = Serial.read();
    //Timer3.stop();
    switch (round(10 * (FSMheader / 10))) // just a hack to parse out cases into categories
    {
      case 10: // opening/closing handshake
        switch (FSMheader - 10)
        {
          case 0: // opening handshake
            Serial.write(5);
            stimulus_writepointer = 0;
            timer_override = true;
            break;
          case 1: // closing handshake
            Serial.write(6);
            timer_override = false;
            break;
        }
        break;
    }
    if (timer_override)
    {
      Timer3.start(1000 * motor_timer_period); // Calls every 10 msec
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
}

void UpdateMotorParams()
{
}

void MoveMotor()
{
  I2Cwriter(motor1_i2c_address,motor_location);
//  // read 'delayed' state
//  if (!motor_override)
//  {
//    stimulus_readpointer = (stimulus_writepointer + delay_feedback_by) % stimulus_array_size;
//    I2Cwriter(motor1_i2c_address, 10 + stimulus_position_array[stimulus_readpointer]);
//  }
//
//  // write the new state
//  stimulus_writepointer = (stimulus_writepointer + 1) % stimulus_array_size;
//  stimulus_position_array[stimulus_writepointer] = stimulus_state[1];
}

