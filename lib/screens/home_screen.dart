import 'package:esp32_smart_controller/providers/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State สำหรับเก็บสถานะ ON/OFF ของแต่ละอุปกรณ์
final ledStateProvider     = StateProvider<bool>((ref) => false);
final relayStateProvider   = StateProvider<bool>((ref) => false);
final buzzerStateProvider  = StateProvider<bool>((ref) => false);
final servoAngleProvider   = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(deviceStatusProvider.notifier).refresh();
      await ref.read(sensorReadingProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status   = ref.watch(deviceStatusProvider);
    final settings = ref.watch(deviceSettingsProvider);
    final service  = ref.read(deviceServiceProvider);

    final ledOn    = ref.watch(ledStateProvider);
    final relayOn  = ref.watch(relayStateProvider);
    final buzzerOn = ref.watch(buzzerStateProvider);
    final servo    = ref.watch(servoAngleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartGarage'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(deviceStatusProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi, color: status.connected ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          status.connected ? 'Connected' : 'Disconnected',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('IP: ${settings.ipAddress}'),
                    Text('WiFi: ${status.ssid}'),
                    Text('Firmware: ${status.firmwareVersion}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('ควบคุมอุปกรณ์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // LED Toggle
            _ToggleCard(
              title: 'LED',
              icon: ledOn ? Icons.lightbulb : Icons.lightbulb_outline,
              iconColor: ledOn ? Colors.yellow : Colors.grey,
              value: ledOn,
              onChanged: (val) async {
                ref.read(ledStateProvider.notifier).state = val;
                await service.setLed(enabled: val);
                _showSnack(context, 'LED ${val ? "ON 💡" : "OFF 🌑"}');
              },
            ),

            // Relay Toggle
            _ToggleCard(
              title: 'Relay',
              icon: Icons.power_settings_new,
              iconColor: relayOn ? Colors.green : Colors.grey,
              value: relayOn,
              onChanged: (val) async {
                ref.read(relayStateProvider.notifier).state = val;
                await service.setRelay(enabled: val);
                _showSnack(context, 'Relay ${val ? "ON ✅" : "OFF ❌"}');
              },
            ),

            // Buzzer Toggle
            _ToggleCard(
              title: 'Buzzer',
              icon: buzzerOn ? Icons.volume_up : Icons.volume_off,
              iconColor: buzzerOn ? Colors.orange : Colors.grey,
              value: buzzerOn,
              onChanged: (val) async {
                ref.read(buzzerStateProvider.notifier).state = val;
                await service.setBuzzer(enabled: val);
                _showSnack(context, 'Buzzer ${val ? "ON 🔔" : "OFF 🔕"}');
              },
            ),

            // Servo Slider
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rotate_right),
                        const SizedBox(width: 8),
                        Text('Servo: $servo°', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    Slider(
                      value: servo.toDouble(),
                      min: 0,
                      max: 180,
                      divisions: 18,
                      label: '$servo°',
                      onChanged: (val) {
                        ref.read(servoAngleProvider.notifier).state = val.toInt();
                      },
                      onChangeEnd: (val) async {
                        await service.setServo(angle: val.toInt());
                        _showSnack(context, 'Servo → ${val.toInt()}°');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: iconColor, size: 28),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(value ? 'ON' : 'OFF'),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
