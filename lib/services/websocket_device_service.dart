import 'package:esp32_smart_controller/core/services/device_comm_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketDeviceService implements DeviceCommService {
  WebSocketDeviceService({required String url}) : _channel = WebSocketChannel.connect(Uri.parse(url));

  final WebSocketChannel _channel;

  @override
  Future<Map<String, dynamic>> getStatus() async => {'protocol': 'websocket', 'status': 'connected'};

  @override
  Future<Map<String, dynamic>> getSensors() async => {'protocol': 'websocket', 'status': 'connected'};

  @override
  Future<Map<String, dynamic>> setLed({required bool enabled}) async => {'protocol': 'websocket', 'enabled': enabled};

  @override
  Future<Map<String, dynamic>> setRelay({required bool enabled}) async => {'protocol': 'websocket', 'enabled': enabled};

  @override
  Future<Map<String, dynamic>> setServo({required int angle}) async => {'protocol': 'websocket', 'angle': angle};

  @override
  Future<Map<String, dynamic>> setBrightness({required int value}) async => {'protocol': 'websocket', 'value': value};

  @override
  Future<Map<String, dynamic>> setRgb({required int red, required int green, required int blue}) async => {'protocol': 'websocket', 'red': red, 'green': green, 'blue': blue};

  @override
  Future<Map<String, dynamic>> setBuzzer({required bool enabled}) async => {'protocol': 'websocket', 'enabled': enabled};
}
