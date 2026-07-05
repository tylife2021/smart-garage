// ============================================
// SmartGarage ESP32 Firmware
// ไม่ hardcode WiFi — ตั้งค่าผ่าน App ได้
// ============================================

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Preferences.h>  // เก็บ WiFi credentials ใน Flash

// ---- Pin Config ----
#define LED_PIN       2
#define RELAY_PIN     4
#define BUZZER_PIN    5
#define SERVO_PIN     13
#define SENSOR_TEMP   34
#define SENSOR_LIGHT  35

// ---- AP Mode (ตอนยังไม่มี WiFi) ----
#define AP_SSID       "SmartGarage-Setup"
#define AP_PASSWORD   "12345678"
#define AP_IP         "192.168.4.1"

WebServer server(80);
Preferences prefs;

bool ledState     = false;
bool relayState   = false;
bool buzzerState  = false;
int  servoAngle   = 90;
int  brightness   = 128;

// ---- อ่าน credentials จาก Flash ----
String savedSSID     = "";
String savedPassword = "";

void loadCredentials() {
  prefs.begin("wifi", true);
  savedSSID     = prefs.getString("ssid", "");
  savedPassword = prefs.getString("pass", "");
  prefs.end();
}

void saveCredentials(const String& ssid, const String& pass) {
  prefs.begin("wifi", false);
  prefs.putString("ssid", ssid);
  prefs.putString("pass", pass);
  prefs.end();
}

// ---- CORS Helper ----
void addCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

// ---- Route: GET /status ----
void handleStatus() {
  addCorsHeaders();
  StaticJsonDocument<256> doc;
  doc["connected"]       = (WiFi.status() == WL_CONNECTED);
  doc["ipAddress"]       = WiFi.localIP().toString();
  doc["ssid"]            = WiFi.SSID();
  doc["firmwareVersion"] = "2.0.0";
  doc["apMode"]          = (WiFi.getMode() == WIFI_AP || WiFi.getMode() == WIFI_AP_STA);
  String out;
  serializeJson(doc, out);
  server.send(200, "application/json", out);
}

// ---- Route: GET /sensor ----
void handleSensor() {
  addCorsHeaders();
  StaticJsonDocument<256> doc;
  // อ่านค่าจาก sensor จริง (หรือ mock ถ้ายังไม่ต่อ sensor)
  doc["temperature"]  = 24.5 + (random(-20, 20) / 10.0);
  doc["humidity"]     = 48.0 + (random(-50, 50) / 10.0);
  doc["soilMoisture"] = 65.0 + (random(-30, 30) / 10.0);
  doc["waterLevel"]   = 30.0 + (random(-20, 20) / 10.0);
  doc["light"]        = analogRead(SENSOR_LIGHT) / 4095.0 * 1000;
  doc["motion"]       = false;
  String out;
  serializeJson(doc, out);
  server.send(200, "application/json", out);
}

// ---- Route: GET /wifi/scan ----
void handleWifiScan() {
  addCorsHeaders();
  int n = WiFi.scanNetworks();
  StaticJsonDocument<2048> doc;
  JsonArray networks = doc.createNestedArray("networks");
  for (int i = 0; i < n; i++) {
    JsonObject net = networks.createNestedObject();
    net["ssid"]    = WiFi.SSID(i);
    net["rssi"]    = WiFi.RSSI(i);
    net["secured"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
  }
  WiFi.scanDelete();
  String out;
  serializeJson(doc, out);
  server.send(200, "application/json", out);
}

// ---- Route: POST /wifi/connect ----
void handleWifiConnect() {
  addCorsHeaders();
  String body = server.arg("plain");
  StaticJsonDocument<256> req;
  DeserializationError err = deserializeJson(req, body);
  if (err) {
    server.send(400, "application/json", "{\"success\":false,\"error\":\"invalid json\"}");
    return;
  }
  String ssid = req["ssid"].as<String>();
  String pass = req["password"].as<String>();

  saveCredentials(ssid, pass);
  WiFi.begin(ssid.c_str(), pass.c_str());

  int timeout = 15000;
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < timeout) {
    delay(500);
  }

  StaticJsonDocument<128> res;
  if (WiFi.status() == WL_CONNECTED) {
    res["success"]   = true;
    res["ipAddress"] = WiFi.localIP().toString();
  } else {
    res["success"] = false;
    res["error"]   = "connection failed";
  }
  String out;
  serializeJson(res, out);
  server.send(200, "application/json", out);
}

// ---- Route: POST /led ----
void handleLed() {
  addCorsHeaders();
  String body = server.arg("plain");
  StaticJsonDocument<128> req;
  deserializeJson(req, body);
  ledState = req["enabled"] | false;
  digitalWrite(LED_PIN, ledState ? HIGH : LOW);
  server.send(200, "application/json", ledState ? "{\"success\":true,\"led\":true}" : "{\"success\":true,\"led\":false}");
}

// ---- Route: POST /relay ----
void handleRelay() {
  addCorsHeaders();
  String body = server.arg("plain");
  StaticJsonDocument<128> req;
  deserializeJson(req, body);
  relayState = req["enabled"] | false;
  digitalWrite(RELAY_PIN, relayState ? HIGH : LOW);
  server.send(200, "application/json", relayState ? "{\"success\":true,\"relay\":true}" : "{\"success\":true,\"relay\":false}");
}

// ---- Route: POST /servo ----
void handleServo() {
  addCorsHeaders();
  String body = server.arg("plain");
  StaticJsonDocument<128> req;
  deserializeJson(req, body);
  servoAngle = req["angle"] | 90;
  servoAngle = constrain(servoAngle, 0, 180);
  // ถ้าใช้ servo library: myServo.write(servoAngle);
  StaticJsonDocument<128> res;
  res["success"]    = true;
  res["servoAngle"] = servoAngle;
  String out;
  serializeJson(res, out);
  server.send(200, "application/json", out);
}

// ---- Route: POST /buzzer ----
void handleBuzzer() {
  addCorsHeaders();
  String body = server.arg("plain");
  StaticJsonDocument<128> req;
  deserializeJson(req, body);
  buzzerState = req["enabled"] | false;
  digitalWrite(BUZZER_PIN, buzzerState ? HIGH : LOW);
  server.send(200, "application/json", buzzerState ? "{\"success\":true,\"buzzer\":true}" : "{\"success\":true,\"buzzer\":false}");
}

// ---- Setup ----
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== SmartGarage ESP32 Firmware v2.0.0 ===");

  // ตั้งค่า GPIO
  pinMode(LED_PIN,    OUTPUT);
  pinMode(RELAY_PIN,  OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // โหลด WiFi credentials
  loadCredentials();

  if (savedSSID.length() > 0) {
    // มี credentials → เชื่อมต่อ WiFi
    Serial.println("Connecting to: " + savedSSID);
    WiFi.mode(WIFI_STA);
    WiFi.begin(savedSSID.c_str(), savedPassword.c_str());

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\n✅ Connected! IP: " + WiFi.localIP().toString());
    } else {
      Serial.println("\n❌ Failed — starting AP mode");
      startAPMode();
    }
  } else {
    // ไม่มี credentials → เปิด AP mode
    Serial.println("No WiFi saved — starting AP mode");
    startAPMode();
  }

  // ลงทะเบียน routes
  server.on("/status",       HTTP_GET,  handleStatus);
  server.on("/sensor",       HTTP_GET,  handleSensor);
  server.on("/wifi/scan",    HTTP_GET,  handleWifiScan);
  server.on("/wifi/connect", HTTP_POST, handleWifiConnect);
  server.on("/led",          HTTP_POST, handleLed);
  server.on("/relay",        HTTP_POST, handleRelay);
  server.on("/servo",        HTTP_POST, handleServo);
  server.on("/buzzer",       HTTP_POST, handleBuzzer);
  server.onNotFound([]() { server.send(404, "application/json", "{\"error\":\"not found\"}"); });

  server.begin();
  Serial.println("HTTP Server started");
}

// ---- AP Mode ----
void startAPMode() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASSWORD);
  Serial.println("AP Mode: " + String(AP_SSID));
  Serial.println("AP IP: " + WiFi.softAPIP().toString());
}

// ---- Loop ----
void loop() {
  server.handleClient();
}
