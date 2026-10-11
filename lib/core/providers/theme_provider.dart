import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final isDark = prefs.getBool('settings_dark_mode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isDark = state == ThemeMode.dark;
    await prefs.setBool('settings_dark_mode', !isDark);
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
