import 'package:esp32_smart_controller/providers/device_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(deviceSettingsProvider);
    final notifier = ref.read(deviceSettingsProvider.notifier);
    final ipController = TextEditingController(text: settings.ipAddress);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: ipController,
                      decoration: const InputDecoration(labelText: 'ESP32 IP Address'),
                      onSubmitted: notifier.updateIp,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: settings.language,
                      items: const [
                        DropdownMenuItem(value: 'EN', child: Text('English')),
                        DropdownMenuItem(value: 'TH', child: Text('ไทย')),
                      ],
                      onChanged: (value) => notifier.updateLanguage(value ?? 'EN'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: settings.darkMode,
                      onChanged: notifier.toggleDarkMode,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AboutListTile(applicationName: 'ESP32 Smart Controller', applicationVersion: '1.0.0', applicationLegalese: 'Built with Flutter and Riverpod'),
          ],
        ),
      ),
    );
  }
}
