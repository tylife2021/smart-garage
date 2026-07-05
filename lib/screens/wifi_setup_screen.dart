import 'package:esp32_smart_controller/providers/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// Provider สำหรับ WiFi list ที่ scan ได้
final wifiListProvider = StateNotifierProvider<WifiListNotifier, WifiListState>((ref) {
  final settings = ref.watch(deviceSettingsProvider);
  return WifiListNotifier(settings.ipAddress);
});

class WifiListState {
  const WifiListState({
    this.networks = const [],
    this.isScanning = false,
    this.error,
  });
  final List<WifiNetwork> networks;
  final bool isScanning;
  final String? error;
}

class WifiNetwork {
  const WifiNetwork({required this.ssid, required this.rssi, required this.secured});
  final String ssid;
  final int rssi;
  final bool secured;

  String get signalIcon {
    if (rssi >= -50) return '▂▄▆█';
    if (rssi >= -65) return '▂▄▆_';
    if (rssi >= -75) return '▂▄__';
    return '▂___';
  }
}

class WifiListNotifier extends StateNotifier<WifiListState> {
  WifiListNotifier(this._ip) : super(const WifiListState());
  final String _ip;

  Future<void> scan() async {
    state = const WifiListState(isScanning: true);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://$_ip',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final response = await dio.get('/wifi/scan');
      final data = response.data as Map<String, dynamic>;
      final list = (data['networks'] as List<dynamic>? ?? [])
          .map((e) => WifiNetwork(
                ssid: e['ssid'] as String? ?? '',
                rssi: e['rssi'] as int? ?? -90,
                secured: e['secured'] as bool? ?? true,
              ))
          .where((n) => n.ssid.isNotEmpty)
          .toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      state = WifiListState(networks: list);
    } catch (e) {
      state = WifiListState(error: 'ไม่สามารถเชื่อมต่อ ESP32 ได้\nตรวจสอบ IP: $_ip');
    }
  }

  Future<bool> connect(String ssid, String password) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://$_ip'));
      final response = await dio.post('/wifi/connect', data: {'ssid': ssid, 'password': password});
      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}

class WifiSetupScreen extends ConsumerStatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  ConsumerState<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends ConsumerState<WifiSetupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(wifiListProvider.notifier).scan());
  }

  void _showConnectDialog(WifiNetwork network) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('เชื่อมต่อ ${network.ssid}'),
        content: network.secured
            ? TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
              )
            : const Text('เครือข่ายนี้ไม่มีรหัสผ่าน'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _doConnect(network.ssid, passwordController.text);
            },
            child: const Text('เชื่อมต่อ'),
          ),
        ],
      ),
    );
  }

  Future<void> _doConnect(String ssid, String password) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('กำลังเชื่อมต่อ $ssid...')));
    final ok = await ref.read(wifiListProvider.notifier).connect(ssid, password);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? '✅ เชื่อมต่อ $ssid สำเร็จ!' : '❌ เชื่อมต่อไม่สำเร็จ'),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
    if (ok) await ref.read(deviceStatusProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final wifiState = ref.watch(wifiListProvider);
    final settings = ref.watch(deviceSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Setup'),
        actions: [
          IconButton(
            icon: wifiState.isScanning
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: wifiState.isScanning ? null : () => ref.read(wifiListProvider.notifier).scan(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ESP32 IP Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.router),
                  const SizedBox(width: 8),
                  Text('ESP32: ${settings.ipAddress}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),

            // WiFi List
            Expanded(
              child: wifiState.isScanning
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังสแกน WiFi...'),
                        ],
                      ),
                    )
                  : wifiState.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(wifiState.error!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => ref.read(wifiListProvider.notifier).scan(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('ลองใหม่'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : wifiState.networks.isEmpty
                          ? const Center(child: Text('ไม่พบ WiFi'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: wifiState.networks.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final network = wifiState.networks[index];
                                return ListTile(
                                  leading: Icon(
                                    network.rssi >= -65 ? Icons.wifi : network.rssi >= -75 ? Icons.wifi_2_bar : Icons.wifi_1_bar,
                                    color: network.rssi >= -65 ? Colors.green : network.rssi >= -75 ? Colors.orange : Colors.red,
                                  ),
                                  title: Text(network.ssid),
                                  subtitle: Text('${network.rssi} dBm'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (network.secured) const Icon(Icons.lock, size: 16),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onTap: () => _showConnectDialog(network),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
