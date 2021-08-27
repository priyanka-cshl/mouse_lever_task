#include <DueTimer.h> 
int camera_pin = 49;
int i = 0;
bool camON = LOW;

void setup() {
  // put your setup code here, to run once:
  pinMode(camera_pin, OUTPUT);
  digitalWrite(camera_pin, camON);
  Timer3.attachInterrupt(TriggerCamera);
  Timer3.start(1000 * 10); // Calls every 10 msec
}

void loop() {
  // put your main code here, to run repeatedly:
  if (i >= 200)
  {
    Timer3.stop();
  }
}

void TriggerCamera()
{
  digitalWrite(camera_pin, camON);
  camON = !camON;
  if (!camON)
  {
    i = i + 1;
  }
}
