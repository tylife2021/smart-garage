import 'package:esp32_smart_controller/providers/ble_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BluetoothScreen extends ConsumerStatefulWidget {
  const BluetoothScreen({super.key});

  @override
  ConsumerState<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends ConsumerState<BluetoothScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bleScanProvider.notifier).startScan());
  }

  @override
  Widget build(BuildContext context) {
    final scanState  = ref.watch(bleScanProvider);
    final connState  = ref.watch(bleConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
        actions: [
          IconButton(
            icon: scanState.isScanning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
            onPressed: scanState.isScanning
                ? () => ref.read(bleScanProvider.notifier).stopScan()
                : () => ref.read(bleScanProvider.notifier).startScan(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Connection Status Banner
            _ConnectionBanner(connState: connState),

            // Device List
            Expanded(
              child: scanState.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(scanState.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref.read(bleScanProvider.notifier).startScan(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    )
                  : scanState.results.isEmpty
                      ? Center(
                          child: scanState.isScanning
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('กำลังค้นหาอุปกรณ์ BLE...'),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('ไม่พบอุปกรณ์ Bluetooth'),
                                  ],
                                ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: scanState.results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = scanState.results[index];
                            final device = result.device;
                            final isConnected = connState.device?.remoteId == device.remoteId &&
                                connState.status == BleStatus.connected;
                            final isConnecting = connState.device?.remoteId == device.remoteId &&
                                connState.status == BleStatus.connecting;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isConnected
                                    ? Colors.blue.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                child: Icon(
                                  Icons.bluetooth,
                                  color: isConnected ? Colors.blue : Colors.grey,
                                ),
                              ),
                              title: Text(
                                device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(device.remoteId.toString()),
                              trailing: isConnecting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : isConnected
                                      ? FilledButton.tonal(
                                          onPressed: () => ref.read(bleConnectionProvider.notifier).disconnect(),
                                          child: const Text('ตัดการเชื่อมต่อ'),
                                        )
                                      : FilledButton(
                                          onPressed: () => ref.read(bleConnectionProvider.notifier).connect(device),
                                          child: const Text('เชื่อมต่อ'),
                                        ),
                              onTap: isConnected ? null : () => ref.read(bleConnectionProvider.notifier).connect(device),
                            );
                          },
                        ),
            ),

            // RSSI legend
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'พบ ${scanState.results.length} อุปกรณ์',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Banner แสดงสถานะการเชื่อมต่อ ----
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.connState});
  final BleConnectionState connState;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String message;
    final IconData icon;

    switch (connState.status) {
      case BleStatus.connected:
        color = Colors.green;
        icon = Icons.bluetooth_connected;
        message = 'เชื่อมต่อกับ ${connState.device?.platformName ?? "อุปกรณ์"} แล้ว';
      case BleStatus.connecting:
        color = Colors.orange;
        icon = Icons.bluetooth_searching;
        message = 'กำลังเชื่อมต่อ...';
      case BleStatus.error:
        color = Colors.red;
        icon = Icons.bluetooth_disabled;
        message = connState.error ?? 'เกิดข้อผิดพลาด';
      case BleStatus.disconnected:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
