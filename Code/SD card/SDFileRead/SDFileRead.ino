/*
  SD card read/write

 This example shows how to read and write data to and from an SD card file
 The circuit:
 * SD card attached to SPI bus as follows:
 ** MOSI - pin 11
 ** MISO - pin 12
 ** CLK - pin 13
 ** CS - pin 4 (for MKRZero SD: SDCARD_SS_PIN)

 created   Nov 2010
 by David A. Mellis
 modified 9 Apr 2012
 by Tom Igoe

 This example code is in the public domain.

 */

#include <SPI.h>
#include <SD.h>
const int SDSelect = 24; // SS pin for the SD card
int ReplayVal = 0;
int byteHIGH = 0;
int byteLOW = 0;
String myval = String(0);
String teststring = String(128);
bool replay_reward_valve_state[2] = {false, false};
bool replay_air_valve_state[2] = {false, false};
int replay_odor_valve_state[2] = {0, 0};
int stimulus_state[] = {0, 0}; // old, new

File myFile;

void setup() {
  // Open serial communications and wait for port to open:
  SerialUSB.begin(9600);
  while (!SerialUSB) {
    ; // wait for serial port to connect. Needed for native USB port only
  }


  SerialUSB.print("Initializing SD card...");

  if (!SD.begin(SDSelect)) {
    SerialUSB.println("initialization failed!");
    return;
  }
  SerialUSB.println("initialization done.");

  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  myFile = SD.open("openloop.txt");
  
  if (myFile) {
    SerialUSB.println("openloop.txt:");

    // read from the file until there's nothing else in it:
    while (myFile.available()) 
    {
      byteHIGH = myFile.read();
      byteLOW = myFile.read();
      ReplayVal = byteHIGH*256+byteLOW;

      replay_reward_valve_state[1] = (ReplayVal >= 20000);
          ReplayVal = ReplayVal - 10000*(1+replay_reward_valve_state[1]);
          stimulus_state[1] = ReplayVal % 1000;
          ReplayVal = (ReplayVal - stimulus_state[1])/1000;
          if (ReplayVal >= 5)
          {
            replay_air_valve_state[1] = true;
            replay_odor_valve_state[1] = ReplayVal - 4;
          }
          else
          {
            replay_air_valve_state[1] = false;
          }
      //myval = myFile.read();
      //mydata = atoi(myval);
      //mydata = mydata - 20;
      SerialUSB.println(stimulus_state[1]);
    }
    // close the file:
    myFile.close();
  } else {
    // if the file didn't open, print an error:
    SerialUSB.println("error opening test.txt");
  }
}

void loop() {
  // nothing happens after setup
}


