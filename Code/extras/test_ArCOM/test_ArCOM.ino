#include "ArCOM.h" // Import the ArCOM library
ArCOM myUSB(Serial); // Create an ArCOM wrapper for the SerialUSB interface
unsigned short myDataArray[10] = {0}; // Create a 1x10 uint16 array
unsigned int arraysize = 10;
int blinktime = 100;
//unsigned int FSMheader = 0;
//variables : serial communication
long serial_clock = micros();
int FSMheader = 0;
int param_index = 0;
unsigned int num_of_params = 30;
//int param_array[30] = {0};
unsigned short param_array[30] = {0};
int param_value = 0;

void setup() {
  // put your setup code here, to run once:
  pinMode(13, OUTPUT);
  Serial.begin(115200); // Initialize the USB serial port
  //myUSB.writeUint16Array(myDataArray,10); // Send the array to MATLAB's buffer
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(13, HIGH);
  delay(blinktime);
  digitalWrite(13, LOW);
  delay(blinktime);

  if (myUSB.available())
  {
    FSMheader = myUSB.readUint16();
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
            break;
          case 2: // Acquisition stop handshake
            myUSB.writeUint16(7);
            break;
          case 3: // read Array
            arraysize = myUSB.readUint16();
            myUSB.readUint16Array(myDataArray,arraysize);
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
        }
        break;
    }
  }
}
