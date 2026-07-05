class DeviceSettings {
  const DeviceSettings({
    required this.ipAddress,
    required this.language,
    required this.darkMode,
  });

  final String ipAddress;
  final String language;
  final bool darkMode;

  DeviceSettings copyWith({
    String? ipAddress,
    String? language,
    bool? darkMode,
  }) {
    return DeviceSettings(
      ipAddress: ipAddress ?? this.ipAddress,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}
