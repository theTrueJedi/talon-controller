// Serial spike: proves Talon's stdlib serial can talk to the C3-Zero.
// Prints HELLO on boot and on each PING line; echoes other lines as
// "ECHO <line>". Blinks the board LED (GPIO10) per received line.

#include <Adafruit_NeoPixel.h>

Adafruit_NeoPixel led(1, 10, NEO_GRB + NEO_KHZ800);
String line;

void hello() { Serial.println("HELLO talon-controller v1"); }

void setup() {
  Serial.begin(115200);
  Serial.setTxTimeoutMs(0);  // never block when no host is reading
  led.begin();
  led.clear();
  led.show();
  delay(300);
  hello();
}

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\r') continue;
    if (c != '\n') {
      if (line.length() < 95) line += c;
      continue;
    }
    if (line == "PING") hello();
    else Serial.println("ECHO " + line);
    line = "";
    led.setPixelColor(0, led.Color(0, 0, 40));
    led.show();
    delay(30);
    led.clear();
    led.show();
  }
}
