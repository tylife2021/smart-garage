class DeviceStatus {
  const DeviceStatus({
    required this.connected,
    required this.ipAddress,
    required this.ssid,
    required this.firmwareVersion,
  });

  final bool connected;
  final String ipAddress;
  final String ssid;
  final String firmwareVersion;

  factory DeviceStatus.initial() => const DeviceStatus(
        connected: false,
        ipAddress: '—',
        ssid: '—',
        firmwareVersion: '—',
      );

  DeviceStatus copyWith({
    bool? connected,
    String? ipAddress,
    String? ssid,
    String? firmwareVersion,
  }) {
    return DeviceStatus(
      connected: connected ?? this.connected,
      ipAddress: ipAddress ?? this.ipAddress,
      ssid: ssid ?? this.ssid,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    );
  }
}
