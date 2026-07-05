import 'package:esp32_smart_controller/screens/bluetooth_screen.dart';
import 'package:esp32_smart_controller/screens/home_screen.dart';
import 'package:esp32_smart_controller/screens/sensor_dashboard_screen.dart';
import 'package:esp32_smart_controller/screens/settings_screen.dart';
import 'package:esp32_smart_controller/screens/wifi_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(path: '/home',      builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/sensors',   builder: (context, state) => const SensorDashboardScreen()),
          GoRoute(path: '/wifi',      builder: (context, state) => const WifiSetupScreen()),
          GoRoute(path: '/bluetooth', builder: (context, state) => const BluetoothScreen()),
          GoRoute(path: '/settings',  builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.contains('/sensors'))   currentIndex = 1;
    if (location.contains('/wifi'))      currentIndex = 2;
    if (location.contains('/bluetooth')) currentIndex = 3;
    if (location.contains('/settings'))  currentIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');      break;
            case 1: context.go('/sensors');   break;
            case 2: context.go('/wifi');      break;
            case 3: context.go('/bluetooth'); break;
            case 4: context.go('/settings');  break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Sensors',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_outlined),
            selectedIcon: Icon(Icons.wifi),
            label: 'WiFi',
          ),
          NavigationDestination(
            icon: Icon(Icons.bluetooth_outlined),
            selectedIcon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
