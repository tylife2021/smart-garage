import 'package:esp32_smart_controller/core/models/device_settings.dart';
import 'package:esp32_smart_controller/core/models/device_status.dart';
import 'package:esp32_smart_controller/core/models/sensor_reading.dart';
import 'package:esp32_smart_controller/core/services/device_comm_service.dart';
import 'package:esp32_smart_controller/services/rest_device_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceServiceProvider = Provider<DeviceCommService>((ref) {
  return RestDeviceService(baseUrl: 'http://192.168.1.50');
});

final deviceStatusProvider = StateNotifierProvider<DeviceStatusController, DeviceStatus>((ref) {
  return DeviceStatusController(ref.read(deviceServiceProvider));
});

final sensorReadingProvider = StateNotifierProvider<SensorReadingController, SensorReading?>((ref) {
  return SensorReadingController(ref.read(deviceServiceProvider));
});

final deviceSettingsProvider = StateNotifierProvider<DeviceSettingsController, DeviceSettings>((ref) {
  return DeviceSettingsController();
});

class DeviceStatusController extends StateNotifier<DeviceStatus> {
  DeviceStatusController(this._service) : super(DeviceStatus.initial());

  final DeviceCommService _service;

  Future<void> refresh() async {
    try {
      final response = await _service.getStatus();
      state = DeviceStatus(
        connected: response['connected'] as bool? ?? true,
        ipAddress: response['ipAddress'] as String? ?? '192.168.1.50',
        ssid: response['ssid'] as String? ?? 'HomeWiFi',
        firmwareVersion: response['firmwareVersion'] as String? ?? '1.0.0',
      );
    } catch (_) {
      state = DeviceStatus.initial();
    }
  }
}

class SensorReadingController extends StateNotifier<SensorReading?> {
  SensorReadingController(this._service) : super(null);

  final DeviceCommService _service;

  Future<void> refresh() async {
    try {
      final response = await _service.getSensors();
      state = SensorReading(
        temperature: (response['temperature'] as num?)?.toDouble() ?? 24.0,
        humidity: (response['humidity'] as num?)?.toDouble() ?? 45.0,
        soilMoisture: (response['soilMoisture'] as num?)?.toDouble() ?? 65.0,
        waterLevel: (response['waterLevel'] as num?)?.toDouble() ?? 30.0,
        light: (response['light'] as num?)?.toDouble() ?? 300.0,
        motion: response['motion'] as bool? ?? false,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      state = null;
    }
  }
}

class DeviceSettingsController extends StateNotifier<DeviceSettings> {
  DeviceSettingsController() : super(const DeviceSettings(ipAddress: '192.168.1.50', language: 'EN', darkMode: false));

  void updateIp(String ipAddress) {
    state = DeviceSettings(ipAddress: ipAddress, language: state.language, darkMode: state.darkMode);
  }

  void updateLanguage(String language) {
    state = DeviceSettings(ipAddress: state.ipAddress, language: language, darkMode: state.darkMode);
  }

  void toggleDarkMode(bool value) {
    state = DeviceSettings(ipAddress: state.ipAddress, language: state.language, darkMode: value);
  }
}
