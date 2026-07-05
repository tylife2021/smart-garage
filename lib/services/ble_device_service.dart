import 'dart:async';
import 'dart:convert';
import 'package:esp32_smart_controller/core/services/device_comm_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// UUID ตรงกับ ESP32 firmware
const String kServiceUUID        = "12345678-1234-1234-1234-123456789abc";
const String kCommandCharUUID    = "12345678-1234-1234-1234-123456789ab1"; // write
const String kResponseCharUUID   = "12345678-1234-1234-1234-123456789ab2"; // notify
const String kSensorCharUUID     = "12345678-1234-1234-1234-123456789ab3"; // notify

class BleDeviceService implements DeviceCommService {
  BleDeviceService({required this.device});

  final BluetoothDevice device;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _responseChar;
  BluetoothCharacteristic? _sensorChar;

  // เชื่อมต่อและค้นหา characteristics
  Future<void> connect() async {
    await device.connect(timeout: const Duration(seconds: 10));
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == kServiceUUID) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == kCommandCharUUID)  _commandChar  = char;
          if (uuid == kResponseCharUUID) _responseChar = char;
          if (uuid == kSensorCharUUID)   _sensorChar   = char;
        }
      }
    }
    // เปิด notify สำหรับ response และ sensor
    await _responseChar?.setNotifyValue(true);
    await _sensorChar?.setNotifyValue(true);
  }

  Future<void> disconnect() async => device.disconnect();

  // ส่ง JSON command และรอ response
  Future<Map<String, dynamic>> _sendCommand(Map<String, dynamic> command) async {
    if (_commandChar == null) return {'error': 'not connected'};

    final bytes = utf8.encode(jsonEncode(command));
    await _commandChar!.write(bytes, withoutResponse: false);

    // รอ response จาก notify characteristic (timeout 3s)
    try {
      final response = await _responseChar!.lastValueStream
          .where((v) => v.isNotEmpty)
          .first
          .timeout(const Duration(seconds: 3));
      return jsonDecode(utf8.decode(response)) as Map<String, dynamic>;
    } catch (_) {
      return {'success': true};
    }
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    return _sendCommand({'cmd': 'status'});
  }

  @override
  Future<Map<String, dynamic>> getSensors() async {
    return _sendCommand({'cmd': 'sensors'});
  }

  @override
  Future<Map<String, dynamic>> setLed({required bool enabled}) async {
    return _sendCommand({'cmd': 'led', 'enabled': enabled});
  }

  @override
  Future<Map<String, dynamic>> setRelay({required bool enabled}) async {
    return _sendCommand({'cmd': 'relay', 'enabled': enabled});
  }

  @override
  Future<Map<String, dynamic>> setServo({required int angle}) async {
    return _sendCommand({'cmd': 'servo', 'angle': angle});
  }

  @override
  Future<Map<String, dynamic>> setBrightness({required int value}) async {
    return _sendCommand({'cmd': 'brightness', 'value': value});
  }

  @override
  Future<Map<String, dynamic>> setRgb({required int red, required int green, required int blue}) async {
    return _sendCommand({'cmd': 'rgb', 'red': red, 'green': green, 'blue': blue});
  }

  @override
  Future<Map<String, dynamic>> setBuzzer({required bool enabled}) async {
    return _sendCommand({'cmd': 'buzzer', 'enabled': enabled});
  }

  // Stream ข้อมูล sensor แบบ real-time จาก BLE notify
  Stream<Map<String, dynamic>> get sensorStream {
    return _sensorChar?.lastValueStream
        .where((v) => v.isNotEmpty)
        .map((v) => jsonDecode(utf8.decode(v)) as Map<String, dynamic>) ??
        const Stream.empty();
  }
}
