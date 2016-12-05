int sensor_in = 51;
//int LED = 13;

void setup() {
  // put your setup code here, to run once:
  pinMode(sensor_in, INPUT_PULLUP);
  //pinMode(LED, OUTPUT);
  Serial.begin(115200);
}

void loop() {
  // put your main code here, to run repeatedly:
  Serial.println(digitalRead(sensor_in));
  //digitalWrite(LED,digitalRead(sensor_in));
}
