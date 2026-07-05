class SensorReading {
  const SensorReading({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.waterLevel,
    required this.light,
    required this.motion,
    required this.timestamp,
  });

  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double waterLevel;
  final double light;
  final bool motion;
  final DateTime timestamp;

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
        humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
        soilMoisture: (json['soilMoisture'] as num?)?.toDouble() ?? 0.0,
        waterLevel: (json['waterLevel'] as num?)?.toDouble() ?? 0.0,
        light: (json['light'] as num?)?.toDouble() ?? 0.0,
        motion: json['motion'] as bool? ?? false,
        timestamp: DateTime.now(),
      );
}
