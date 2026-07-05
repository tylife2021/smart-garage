import 'package:esp32_smart_controller/providers/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final status = ref.watch(deviceStatusProvider);
    final sensors = ref.watch(sensorReadingProvider);
    final settings = ref.watch(deviceSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Smart Controller'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(status: status, settings: settings),
            const SizedBox(height: 16),
            _ControlGrid(sensors: sensors),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.settings});

  final dynamic status;
  final dynamic settings;

  @override
  Widget build(BuildContext context) {
    final isConnected = status.connected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: isConnected ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(isConnected ? 'Connected' : 'Disconnected', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'IP Address', value: settings.ipAddress),
            _InfoRow(label: 'WiFi SSID', value: status.ssid),
            _InfoRow(label: 'Firmware', value: status.firmwareVersion),
            _InfoRow(label: 'Protocol', value: 'REST API'),
          ],
        ),
      ),
    );
  }
}

class _ControlGrid extends ConsumerWidget {
  const _ControlGrid({required this.sensors});

  final dynamic sensors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(deviceServiceProvider);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _ActionCard(
          title: 'LED',
          icon: Icons.lightbulb_outline,
          onTap: () async => service.setLed(enabled: true),
        ),
        _ActionCard(
          title: 'Relay',
          icon: Icons.power_settings_new,
          onTap: () async => service.setRelay(enabled: true),
        ),
        _ActionCard(
          title: 'Servo',
          icon: Icons.rotate_right,
          onTap: () async => service.setServo(angle: 90),
        ),
        _ActionCard(
          title: 'Buzzer',
          icon: Icons.volume_up,
          onTap: () async => service.setBuzzer(enabled: true),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () async {
          await onTap();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title command sent')));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
