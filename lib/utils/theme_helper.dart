import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeHelper {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';

  // Get theme mode from SharedPreferences
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey) ?? 'system';
    
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Save theme mode to SharedPreferences
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
        break;
    }
    
    await prefs.setString(_themeModeKey, modeString);
  }

  // Get theme color from SharedPreferences
  static Future<String> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeColorKey) ?? 'green';
  }

  // Save theme color to SharedPreferences
  static Future<void> saveThemeColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, color);
  }

  // Get Color from color name
  static Color getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  // Create light theme
  static ThemeData getLightTheme(String colorName) {
    final seedColor = getColorFromName(colorName);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  // Create dark theme
  static ThemeData getDarkTheme(String colorName) {
    final seedColor = getColorFromName(colorName);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
