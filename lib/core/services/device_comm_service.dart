abstract class DeviceCommService {
  Future<Map<String, dynamic>> getStatus();
  Future<Map<String, dynamic>> getSensors();
  Future<Map<String, dynamic>> setLed({required bool enabled});
  Future<Map<String, dynamic>> setRelay({required bool enabled});
  Future<Map<String, dynamic>> setServo({required int angle});
  Future<Map<String, dynamic>> setBrightness({required int value});
  Future<Map<String, dynamic>> setRgb({required int red, required int green, required int blue});
  Future<Map<String, dynamic>> setBuzzer({required bool enabled});
}
