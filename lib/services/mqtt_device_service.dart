import 'package:esp32_smart_controller/core/services/device_comm_service.dart';

class MqttDeviceService implements DeviceCommService {
  @override
  Future<Map<String, dynamic>> getStatus() async => {'protocol': 'mqtt', 'status': 'ready'};

  @override
  Future<Map<String, dynamic>> getSensors() async => {'protocol': 'mqtt', 'status': 'ready'};

  @override
  Future<Map<String, dynamic>> setLed({required bool enabled}) async => {'protocol': 'mqtt', 'enabled': enabled};

  @override
  Future<Map<String, dynamic>> setRelay({required bool enabled}) async => {'protocol': 'mqtt', 'enabled': enabled};

  @override
  Future<Map<String, dynamic>> setServo({required int angle}) async => {'protocol': 'mqtt', 'angle': angle};

  @override
  Future<Map<String, dynamic>> setBrightness({required int value}) async => {'protocol': 'mqtt', 'value': value};

  @override
  Future<Map<String, dynamic>> setRgb({required int red, required int green, required int blue}) async => {'protocol': 'mqtt', 'red': red, 'green': green, 'blue': blue};

  @override
  Future<Map<String, dynamic>> setBuzzer({required bool enabled}) async => {'protocol': 'mqtt', 'enabled': enabled};
}
