import 'package:flutter/material.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode;
  ThemeMode get mode => _mode;

  ThemeProvider(this._mode);

  static Future<ThemeProvider> load() async {
    final String stored = await getThemeModeValue();
    return ThemeProvider(ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system));
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await setThemeModeValue(mode.name);
  }
}
