import 'package:flutter/material.dart';
import 'core/app_settings_provider.dart';

class AppTheme {
  static ThemeData get darkTheme => getTheme(AppThemeMode.obsidian);

  static ThemeData getTheme(AppThemeMode mode) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: mode.backgroundColor,
      canvasColor: mode.backgroundColor,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.tealAccent,
        surface: mode.surfaceColor,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: mode.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: mode.surfaceColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
