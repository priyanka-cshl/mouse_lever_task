const byte end_stop_pin_left = 2;
const byte end_stop_pin_right = 3;
const byte home_pin = 51;

void setup() {
  // put your setup code here, to run once:
  pinMode(end_stop_pin_left, INPUT_PULLUP);
  pinMode(end_stop_pin_right, INPUT_PULLUP);
  pinMode(home_pin, INPUT_PULLUP);
  //attachInterrupt(digitalPinToInterrupt(end_stop_pin_left), SafetyStop, RISING);
  //attachInterrupt(digitalPinToInterrupt(end_stop_pin_right), SafetyStop, RISING);
  Serial.begin (115200);
}

void loop() {
  // put your main code here, to run repeatedly:
  //Serial.println(digitalRead(end_stop_pin_right));
  //Serial.println(digitalRead(end_stop_pin_left));
  Serial.println(digitalRead(home_pin));
}

void SafetyStop()
{
  Serial.println(1);
  delay(100);
  Serial.println(0);
  delay(100);
}
