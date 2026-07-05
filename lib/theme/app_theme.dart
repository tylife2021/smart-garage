import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF60A5FA),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      );
}
