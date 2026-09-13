import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ThemeStorage {
  static const _key = 'theme_mode';

  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
