import 'dart:async';
import 'package:esp32_smart_controller/core/models/sensor_reading.dart';
import 'package:esp32_smart_controller/providers/device_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// เก็บ history สูงสุด 20 จุด สำหรับ chart
final sensorHistoryProvider = StateProvider<List<SensorReading>>((ref) => []);

class SensorDashboardScreen extends ConsumerStatefulWidget {
  const SensorDashboardScreen({super.key});

  @override
  ConsumerState<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends ConsumerState<SensorDashboardScreen> {
  Timer? _timer;
  String _selectedChart = 'temperature';

  @override
  void initState() {
    super.initState();
    _fetchAndRecord();
    // auto-refresh ทุก 5 วินาที
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchAndRecord());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndRecord() async {
    await ref.read(sensorReadingProvider.notifier).refresh();
    final reading = ref.read(sensorReadingProvider);
    if (reading != null) {
      final history = [...ref.read(sensorHistoryProvider), reading];
      // เก็บแค่ 20 จุดล่าสุด
      ref.read(sensorHistoryProvider.notifier).state =
          history.length > 20 ? history.sublist(history.length - 20) : history;
    }
  }

  List<FlSpot> _getSpots(String field) {
    final history = ref.watch(sensorHistoryProvider);
    return history.asMap().entries.map((e) {
      final i = e.key.toDouble();
      final r = e.value;
      final v = switch (field) {
        'temperature' => r.temperature,
        'humidity' => r.humidity,
        'soilMoisture' => r.soilMoisture,
        'waterLevel' => r.waterLevel,
        'light' => r.light / 10, // scale ลง
        _ => r.temperature,
      };
      return FlSpot(i, v);
    }).toList();
  }

  Color _chartColor(String field) => switch (field) {
        'temperature' => Colors.orange,
        'humidity' => Colors.blue,
        'soilMoisture' => Colors.green,
        'waterLevel' => Colors.cyan,
        'light' => Colors.amber,
        _ => Colors.purple,
      };

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(sensorReadingProvider);
    final history = ref.watch(sensorHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAndRecord,
          ),
        ],
      ),
      body: SafeArea(
        child: reading == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังดึงข้อมูล sensor...'),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Timestamp
                  Text(
                    'อัปเดต: ${_formatTime(reading.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),

                  // Metric Cards
                  _MetricCard(
                    title: 'Temperature',
                    value: '${reading.temperature.toStringAsFixed(1)}°C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedChart = 'temperature'),
                    selected: _selectedChart == 'temperature',
                  ),
                  const SizedBox(height: 8),
                  _MetricCard(
                    title: 'Humidity',
                    value: '${reading.humidity.toStringAsFixed(1)}%',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    onTap: () => setState(() => _selectedChart = 'humidity'),
                    selected: _selectedChart == 'humidity',
                  ),
                  const SizedBox(height: 8),
                  _MetricCard(
                    title: 'Soil Moisture',
                    value: '${reading.soilMoisture.toStringAsFixed(1)}%',
                    icon: Icons.grass,
                    color: Colors.green,
                    onTap: () => setState(() => _selectedChart = 'soilMoisture'),
                    selected: _selectedChart == 'soilMoisture',
                  ),
                  const SizedBox(height: 8),
                  _MetricCard(
                    title: 'Water Level',
                    value: '${reading.waterLevel.toStringAsFixed(1)}%',
                    icon: Icons.water,
                    color: Colors.cyan,
                    onTap: () => setState(() => _selectedChart = 'waterLevel'),
                    selected: _selectedChart == 'waterLevel',
                  ),
                  const SizedBox(height: 8),
                  _MetricCard(
                    title: 'Light',
                    value: '${reading.light.toStringAsFixed(0)} lx',
                    icon: Icons.light_mode,
                    color: Colors.amber,
                    onTap: () => setState(() => _selectedChart = 'light'),
                    selected: _selectedChart == 'light',
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: reading.motion ? Colors.red : Colors.grey,
                        child: Icon(Icons.motion_photos_on, color: Colors.white),
                      ),
                      title: const Text('Motion'),
                      trailing: Text(
                        reading.motion ? '🔴 Detected' : '⚪ Idle',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),

                  // Chart
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'กราฟ: ${_chartLabel(_selectedChart)} (${history.length} จุด)',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: history.length < 2
                                ? const Center(child: Text('รอข้อมูลเพิ่มเติม...'))
                                : LineChart(
                                    LineChartData(
                                      gridData: const FlGridData(show: true),
                                      titlesData: const FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _getSpots(_selectedChart),
                                          isCurved: true,
                                          color: _chartColor(_selectedChart),
                                          barWidth: 3,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: _chartColor(_selectedChart).withOpacity(0.2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

  String _chartLabel(String field) => switch (field) {
        'temperature' => 'Temperature (°C)',
        'humidity' => 'Humidity (%)',
        'soilMoisture' => 'Soil Moisture (%)',
        'waterLevel' => 'Water Level (%)',
        'light' => 'Light (lx/10)',
        _ => field,
      };

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.selected,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        title: Text(title),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
