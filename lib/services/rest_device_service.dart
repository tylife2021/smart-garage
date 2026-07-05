import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:esp32_smart_controller/core/services/device_comm_service.dart';

class RestDeviceService implements DeviceCommService {
  RestDeviceService({required String baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getStatus() async {
    final response = await _dio.get('/status');
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> getSensors() async {
    final response = await _dio.get('/sensor');
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> setLed({required bool enabled}) async {
    final response = await _dio.post('/led', data: {'enabled': enabled});
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> setRelay({required bool enabled}) async {
    final response = await _dio.post('/relay', data: {'enabled': enabled});
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> setServo({required int angle}) async {
    final response = await _dio.post('/servo', data: {'angle': angle});
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> setBrightness({required int value}) async {
    final response = await _dio.post('/brightness', data: {'value': value});
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> setRgb({required int red, required int green, required int blue}) async {
    final response = await _dio.post('/rgb', data: {'red': red, 'green': green, 'blue': blue});
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> setBuzzer({required bool enabled}) async {
    final response = await _dio.post('/buzzer', data: {'enabled': enabled});
    return _decode(response);
  }

  Map<String, dynamic> _decode(Response<dynamic> response) {
    if (response.data is String) {
      return jsonDecode(response.data as String) as Map<String, dynamic>;
    }
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'status': 'ok'};
  }
}
