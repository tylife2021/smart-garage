#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

const char* ssid = "Padtha157";
const char* password = "0854909157";

WebServer server(80);

bool ledState = false;
bool relayState = false;
int servoAngle = 90;
int brightness = 128;
int red = 0, green = 0, blue = 0;
bool buzzerState = false;

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(2, OUTPUT);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println(WiFi.localIP());

  server.on("/status", HTTP_GET, []() {
    StaticJsonDocument<256> doc;
    doc["connected"] = true;
    doc["ipAddress"] = WiFi.localIP().toString();
    doc["ssid"] = WiFi.SSID();
    doc["firmwareVersion"] = "1.0.0";
    String output;
    serializeJson(doc, output);
    server.send(200, "application/json", output);
  });

  server.on("/sensor", HTTP_GET, []() {
    StaticJsonDocument<256> doc;
    doc["temperature"] = 24.5;
    doc["humidity"] = 48.2;
    doc["soilMoisture"] = 65.0;
    doc["waterLevel"] = 30.0;
    doc["light"] = 300;
    doc["motion"] = false;
    String output;
    serializeJson(doc, output);
    server.send(200, "application/json", output);
  });

  server.on("/led", HTTP_POST, []() {
    ledState = server.arg("enabled") == "true";
    digitalWrite(LED_BUILTIN, ledState ? HIGH : LOW);
    StaticJsonDocument<128> doc;
    doc["success"] = true;
    doc["led"] = ledState;
    String output;
    serializeJson(doc, output);
    server.send(200, "application/json", output);
  });

  server.on("/relay", HTTP_POST, []() {
    relayState = server.arg("enabled") == "true";
    digitalWrite(2, relayState ? HIGH : LOW);
    StaticJsonDocument<128> doc;
    doc["success"] = true;
    doc["relay"] = relayState;
    String output;
    serializeJson(doc, output);
    server.send(200, "application/json", output);
  });

  server.on("/servo", HTTP_POST, []() {
    servoAngle = server.arg("angle").toInt();
    StaticJsonDocument<128> doc;
    doc["success"] = true;
    doc["servoAngle"] = servoAngle;
    String output;
    serializeJson(doc, output);
    server.send(200, "application/json", output);
  });

  server.begin();
}

void loop() {
  server.handleClient();
}
