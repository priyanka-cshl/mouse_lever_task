#include <SPI.h> // library for SPI communication - to DAC

// declare pins
int encoderA = 53;
int encoderB = 51;
int encoderZ = 49;
int home_pin = 47;
//int DAC_pin = DAC1;
volatile int rotary_position = 0;
long rotary_position_out = 0L;
int position_sign = 1; // 1 = positive, -1 = negative;

int counter = 0;

// SPI related
int dac_spi_pin = 22;

void setup() {
  // put your setup code here, to run once:
  pinMode(encoderA,INPUT);
  pinMode(encoderB,INPUT);
  pinMode(home_pin,INPUT);
  analogWriteResolution(12);
  attachInterrupt(home_pin, home_interrupt, RISING); 
  //attachInterrupt(home_pin, reenable_interrupt, FALLING) ; 
  attachInterrupt(encoderA,rotary,RISING);

  // set up SPI
  pinMode (dac_spi_pin, OUTPUT);
  SPI.begin(dac_spi_pin);
  Serial.begin(115200);
}

void home_interrupt()
{
  detachInterrupt(encoderA);
  rotary_position = 0;  
  attachInterrupt(encoderA,rotary,RISING);
}

void reenable_interrupt()
{
  attachInterrupt(encoderA,rotary,RISING);
}

void rotary() // interrup routine for rising edge on encoderA
{
  rotary_position = rotary_position + (2*(digitalRead(encoderB)) - 1);
}

void loop() {
  // put your main code here, to run repeatedly:
  if (rotary_position<0)
  {
    position_sign = -1;
  }
  else
  {
    position_sign = 1;
  }
  // constrain rotary position between 0-1023
  rotary_position = abs(rotary_position) % 1024;
  rotary_position = rotary_position * position_sign;
  //analogWrite(DAC_pin,3*(rotary_position+650));
  //remap before sending to DAC
  rotary_position_out = map(rotary_position, -550, 350, 0, 65534);
  SPIWriter(dac_spi_pin, rotary_position_out);
//  Serial.print(rotary_position);
//  Serial.print(" ");
//  Serial.println(rotary_position_out);
  
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
