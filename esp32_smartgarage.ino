// ============================================
// SmartGarage ESP32 Firmware v3.0
// รองรับทั้ง WiFi REST API และ Bluetooth BLE
// ============================================

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ---- Pin Config ----
#define LED_PIN     2
#define RELAY_PIN   4
#define BUZZER_PIN  5
#define SERVO_PIN   13

// ---- WiFi AP Mode ----
#define AP_SSID     "SmartGarage-Setup"
#define AP_PASSWORD "12345678"

// ---- BLE UUIDs (ตรงกับ Flutter app) ----
#define BLE_DEVICE_NAME   "SmartGarage"
#define SERVICE_UUID      "12345678-1234-1234-1234-123456789abc"
#define COMMAND_CHAR_UUID "12345678-1234-1234-1234-123456789ab1"  // write
#define RESPONSE_CHAR_UUID "12345678-1234-1234-1234-123456789ab2" // notify
#define SENSOR_CHAR_UUID  "12345678-1234-1234-1234-123456789ab3"  // notify

WebServer server(80);
Preferences prefs;

// BLE objects
BLEServer*         bleServer     = nullptr;
BLECharacteristic* cmdChar       = nullptr;
BLECharacteristic* responseChar  = nullptr;
BLECharacteristic* sensorChar    = nullptr;
bool               bleConnected  = false;

// States
bool ledState    = false;
bool relayState  = false;
bool buzzerState = false;
int  servoAngle  = 90;

String savedSSID = "";
String savedPass = "";

// ---- Shared: execute command JSON ----
String executeCommand(const String& json) {
  StaticJsonDocument<256> req;
  if (deserializeJson(req, json) != DeserializationError::Ok) {
    return "{\"error\":\"invalid json\"}";
  }

  String cmd = req["cmd"].as<String>();
  StaticJsonDocument<128> res;

  if (cmd == "status") {
    res["connected"]       = (WiFi.status() == WL_CONNECTED);
    res["ipAddress"]       = WiFi.localIP().toString();
    res["ssid"]            = WiFi.SSID();
    res["firmwareVersion"] = "3.0.0";
  } else if (cmd == "sensors") {
    res["temperature"]  = 24.5 + (random(-20, 20) / 10.0);
    res["humidity"]     = 48.0 + (random(-50, 50) / 10.0);
    res["soilMoisture"] = 65.0 + (random(-30, 30) / 10.0);
    res["waterLevel"]   = 30.0 + (random(-20, 20) / 10.0);
    res["light"]        = (float)analogRead(35) / 4095.0 * 1000.0;
    res["motion"]       = false;
  } else if (cmd == "led") {
    ledState = req["enabled"] | false;
    digitalWrite(LED_PIN, ledState);
    res["success"] = true;
    res["led"]     = ledState;
  } else if (cmd == "relay") {
    relayState = req["enabled"] | false;
    digitalWrite(RELAY_PIN, relayState);
    res["success"] = true;
    res["relay"]   = relayState;
  } else if (cmd == "servo") {
    servoAngle = constrain((int)(req["angle"] | 90), 0, 180);
    res["success"]    = true;
    res["servoAngle"] = servoAngle;
  } else if (cmd == "buzzer") {
    buzzerState = req["enabled"] | false;
    digitalWrite(BUZZER_PIN, buzzerState);
    res["success"] = true;
    res["buzzer"]  = buzzerState;
  } else {
    res["error"] = "unknown command";
  }

  String out;
  serializeJson(res, out);
  return out;
}

// ---- BLE Callbacks ----
class BleServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* s) override {
    bleConnected = true;
    Serial.println("BLE: Client connected");
  }
  void onDisconnect(BLEServer* s) override {
    bleConnected = false;
    Serial.println("BLE: Client disconnected — restarting advertising");
    BLEDevice::startAdvertising();
  }
};

class CommandCharCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String value = c->getValue().c_str();
    Serial.println("BLE CMD: " + value);
    String result = executeCommand(value);
    responseChar->setValue(result.c_str());
    responseChar->notify();
  }
};

// ---- BLE Setup ----
void setupBLE() {
  BLEDevice::init(BLE_DEVICE_NAME);
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new BleServerCallbacks());

  BLEService* service = bleServer->createService(SERVICE_UUID);

  // Command characteristic (write)
  cmdChar = service->createCharacteristic(
    COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  cmdChar->setCallbacks(new CommandCharCallbacks());

  // Response characteristic (notify)
  responseChar = service->createCharacteristic(
    RESPONSE_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  responseChar->addDescriptor(new BLE2902());

  // Sensor characteristic (notify)
  sensorChar = service->createCharacteristic(
    SENSOR_CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  sensorChar->addDescriptor(new BLE2902());

  service->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("BLE: Advertising as '" BLE_DEVICE_NAME "'");
}

// ---- WiFi Setup ----
void loadCredentials() {
  prefs.begin("wifi", true);
  savedSSID = prefs.getString("ssid", "");
  savedPass = prefs.getString("pass", "");
  prefs.end();
}

void saveCredentials(const String& ssid, const String& pass) {
  prefs.begin("wifi", false);
  prefs.putString("ssid", ssid);
  prefs.putString("pass", pass);
  prefs.end();
}

void startAPMode() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASSWORD);
  Serial.println("AP Mode: " + String(AP_SSID) + " / IP: " + WiFi.softAPIP().toString());
}

// ---- HTTP Routes ----
void setupHTTPRoutes() {
  server.on("/status", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    StaticJsonDocument<256> doc;
    doc["connected"]       = (WiFi.status() == WL_CONNECTED);
    doc["ipAddress"]       = WiFi.localIP().toString();
    doc["ssid"]            = WiFi.SSID();
    doc["firmwareVersion"] = "3.0.0";
    doc["bleConnected"]    = bleConnected;
    String out; serializeJson(doc, out);
    server.send(200, "application/json", out);
  });

  server.on("/sensor", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    String result = executeCommand("{\"cmd\":\"sensors\"}");
    server.send(200, "application/json", result);
  });

  server.on("/wifi/scan", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
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
    String out; serializeJson(doc, out);
    server.send(200, "application/json", out);
  });

  server.on("/wifi/connect", HTTP_POST, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    String body = server.arg("plain");
    StaticJsonDocument<256> req;
    deserializeJson(req, body);
    String ssid = req["ssid"].as<String>();
    String pass = req["password"].as<String>();
    saveCredentials(ssid, pass);
    WiFi.begin(ssid.c_str(), pass.c_str());
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) delay(500);
    StaticJsonDocument<128> res;
    res["success"]   = (WiFi.status() == WL_CONNECTED);
    res["ipAddress"] = WiFi.localIP().toString();
    String out; serializeJson(res, out);
    server.send(200, "application/json", out);
  });

  server.on("/led",    HTTP_POST, []() { server.send(200, "application/json", executeCommand("{\"cmd\":\"led\",\"enabled\":" + String(server.arg("plain").indexOf("true") >= 0 ? "true" : "false") + "}")); });
  server.on("/relay",  HTTP_POST, []() { server.send(200, "application/json", executeCommand("{\"cmd\":\"relay\",\"enabled\":" + String(server.arg("plain").indexOf("true") >= 0 ? "true" : "false") + "}")); });
  server.on("/buzzer", HTTP_POST, []() { server.send(200, "application/json", executeCommand("{\"cmd\":\"buzzer\",\"enabled\":" + String(server.arg("plain").indexOf("true") >= 0 ? "true" : "false") + "}")); });
  server.on("/servo",  HTTP_POST, []() { server.send(200, "application/json", executeCommand(server.arg("plain"))); });

  server.onNotFound([]() { server.send(404, "application/json", "{\"error\":\"not found\"}"); });
  server.begin();
}

// ---- Setup ----
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== SmartGarage ESP32 v3.0 (WiFi + BLE) ===");

  pinMode(LED_PIN,    OUTPUT);
  pinMode(RELAY_PIN,  OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  // เริ่ม BLE
  setupBLE();

  // เริ่ม WiFi
  loadCredentials();
  if (savedSSID.length() > 0) {
    WiFi.mode(WIFI_STA);
    WiFi.begin(savedSSID.c_str(), savedPass.c_str());
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts++ < 20) { delay(500); Serial.print("."); }
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\n✅ WiFi: " + WiFi.localIP().toString());
    } else {
      Serial.println("\n❌ WiFi failed — AP mode");
      startAPMode();
    }
  } else {
    startAPMode();
  }

  setupHTTPRoutes();
  Serial.println("Ready! WiFi + BLE both active.");
}

// ---- Loop ----
unsigned long lastSensorNotify = 0;

void loop() {
  server.handleClient();

  // ส่ง sensor data ผ่าน BLE notify ทุก 5 วินาที
  if (bleConnected && millis() - lastSensorNotify > 5000) {
    lastSensorNotify = millis();
    String sensorData = executeCommand("{\"cmd\":\"sensors\"}");
    sensorChar->setValue(sensorData.c_str());
    sensorChar->notify();
  }
}
