// SmartGarage ESP32 - Minimal Version
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ---- ตั้ง WiFi ตรงนี้ ----
const char* ssid     = "Padtha157";
const char* password = "0854909157";

WebServer server(80);

bool ledState   = false;
bool relayState = false;

void setup() {
  Serial.begin(115200);
  pinMode(2, OUTPUT);
  pinMode(4, OUTPUT);

  WiFi.begin(ssid, password);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500); Serial.print(".");
  }
  Serial.println("\nIP: " + WiFi.localIP().toString());

  server.on("/status", HTTP_GET, []() {
    StaticJsonDocument<128> d;
    d["connected"] = true;
    d["ip"]        = WiFi.localIP().toString();
    d["ssid"]      = WiFi.SSID();
    d["firmware"]  = "1.0.0";
    String out; serializeJson(d, out);
    server.send(200, "application/json", out);
  });

  server.on("/sensor", HTTP_GET, []() {
    StaticJsonDocument<128> d;
    d["temperature"]  = 25.0;
    d["humidity"]     = 50.0;
    d["soilMoisture"] = 60.0;
    d["waterLevel"]   = 40.0;
    d["light"]        = 300.0;
    d["motion"]       = false;
    String out; serializeJson(d, out);
    server.send(200, "application/json", out);
  });

  server.on("/led", HTTP_POST, []() {
    ledState = server.arg("plain").indexOf("true") >= 0;
    digitalWrite(2, ledState);
    server.send(200, "application/json", "{\"success\":true}");
  });

  server.on("/relay", HTTP_POST, []() {
    relayState = server.arg("plain").indexOf("true") >= 0;
    digitalWrite(4, relayState);
    server.send(200, "application/json", "{\"success\":true}");
  });

  server.on("/servo",  HTTP_POST, []() { server.send(200, "application/json", "{\"success\":true}"); });
  server.on("/buzzer", HTTP_POST, []() { server.send(200, "application/json", "{\"success\":true}"); });

  server.begin();
  Serial.println("Server ready!");
}

void loop() {
  server.handleClient();
}
