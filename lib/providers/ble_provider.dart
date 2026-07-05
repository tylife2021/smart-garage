import 'dart:async';
import 'package:esp32_smart_controller/services/ble_device_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---- BLE Scan State ----
class BleScanState {
  const BleScanState({
    this.results = const [],
    this.isScanning = false,
    this.error,
  });
  final List<ScanResult> results;
  final bool isScanning;
  final String? error;
}

// ---- BLE Connection State ----
class BleConnectionState {
  const BleConnectionState({
    this.device,
    this.service,
    this.status = BleStatus.disconnected,
    this.error,
  });
  final BluetoothDevice? device;
  final BleDeviceService? service;
  final BleStatus status;
  final String? error;
}

enum BleStatus { disconnected, connecting, connected, error }

// ---- Scan Provider ----
final bleScanProvider = StateNotifierProvider<BleScanNotifier, BleScanState>((ref) {
  return BleScanNotifier();
});

class BleScanNotifier extends StateNotifier<BleScanState> {
  BleScanNotifier() : super(const BleScanState());

  StreamSubscription? _scanSub;

  Future<void> startScan() async {
    // ตรวจสอบว่า Bluetooth เปิดอยู่ไหม
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      state = const BleScanState(error: 'กรุณาเปิด Bluetooth ก่อน');
      return;
    }

    state = const BleScanState(isScanning: true);
    final found = <String, ScanResult>{};

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName.isNotEmpty) {
          found[r.device.remoteId.toString()] = r;
        }
      }
      state = BleScanState(results: found.values.toList(), isScanning: true);
    });

    // scan 5 วินาที
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();

    state = BleScanState(results: found.values.toList(), isScanning: false);
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    state = BleScanState(results: state.results, isScanning: false);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }
}

// ---- Connection Provider ----
final bleConnectionProvider = StateNotifierProvider<BleConnectionNotifier, BleConnectionState>((ref) {
  return BleConnectionNotifier();
});

class BleConnectionNotifier extends StateNotifier<BleConnectionState> {
  BleConnectionNotifier() : super(const BleConnectionState());

  StreamSubscription? _connectionSub;

  Future<void> connect(BluetoothDevice device) async {
    state = BleConnectionState(device: device, status: BleStatus.connecting);

    try {
      final service = BleDeviceService(device: device);
      await service.connect();

      // ติดตาม connection state
      _connectionSub?.cancel();
      _connectionSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          state = const BleConnectionState(status: BleStatus.disconnected);
        }
      });

      state = BleConnectionState(
        device: device,
        service: service,
        status: BleStatus.connected,
      );
    } catch (e) {
      state = BleConnectionState(
        status: BleStatus.error,
        error: 'เชื่อมต่อไม่สำเร็จ: ${e.toString()}',
      );
    }
  }

  Future<void> disconnect() async {
    await state.service?.disconnect();
    _connectionSub?.cancel();
    state = const BleConnectionState(status: BleStatus.disconnected);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}
