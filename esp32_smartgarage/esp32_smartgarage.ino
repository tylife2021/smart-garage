// SmartGarage ESP32 - Minimal Version
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

const char* ssid     = "Padtha157";
const char* password = "0854909157";

WebServer server(80);

bool ledState   = false;
bool relayState = false;

void cors() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

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
    cors();
    StaticJsonDocument<128> d;
    d["connected"] = true;
    d["ipAddress"] = WiFi.localIP().toString();
    d["ssid"]      = WiFi.SSID();
    d["firmwareVersion"] = "1.0.0";
    String out; serializeJson(d, out);
    server.send(200, "application/json", out);
  });

  server.on("/sensor", HTTP_GET, []() {
    cors();
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
    cors();
    ledState = server.arg("plain").indexOf("true") >= 0;
    digitalWrite(2, ledState);
    server.send(200, "application/json", "{\"success\":true}");
  });

  server.on("/relay", HTTP_POST, []() {
    cors();
    relayState = server.arg("plain").indexOf("true") >= 0;
    digitalWrite(4, relayState);
    server.send(200, "application/json", "{\"success\":true}");
  });

  server.on("/servo",  HTTP_POST, []() { cors(); server.send(200, "application/json", "{\"success\":true}"); });
  server.on("/buzzer", HTTP_POST, []() { cors(); server.send(200, "application/json", "{\"success\":true}"); });

  // Handle preflight OPTIONS
  server.onNotFound([]() {
    cors();
    if (server.method() == HTTP_OPTIONS) {
      server.send(204);
    } else {
      server.send(404, "application/json", "{\"error\":\"not found\"}");
    }
  });

  server.begin();
  Serial.println("Server ready!");
}

void loop() {
  server.handleClient();
}
