import 'package:flutter/material.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  Settings? _settings;
  Settings? get settings => _settings;

  final DatabaseService _db = DatabaseService();

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _settings = await _db.getSettings();
    notifyListeners();
  }

  // Example: toggle notification enabled
  Future<void> setNotificationEnabled(bool enabled) async {
    if (_settings == null) return;
    await _db.updateNotificationEnabled(enabled);
    _settings = Settings(
      id: _settings!.id,
      predictionMode: _settings!.predictionMode,
      darkMode: _settings!.darkMode,
      notificationEnabled: enabled,
      notificationDaysBefore: _settings!.notificationDaysBefore,
      notificationTime: _settings!.notificationTime,
    );
    await _db.updateSettings(_settings!);
    notifyListeners();
  }

  Future<void> setPredictionMode(String mode) async {
    if (_settings == null) return;
    await _db.updatePredictionMode(mode);
    _settings = Settings(
      id: _settings!.id,
      predictionMode: mode,
      darkMode: _settings!.darkMode,
      notificationEnabled: _settings!.notificationEnabled,
      notificationDaysBefore: _settings!.notificationDaysBefore,
      notificationTime: _settings!.notificationTime,
    );
    await _db.updateSettings(_settings!);
    notifyListeners();
  }

  Future<void> updateSettings({
    String? predictionMode,
    bool? darkMode,
    int? notificationDaysBefore,
    TimeOfDay? notificationTime,
  }) async {
    if (_settings == null) return;

    final updatedSettings = Settings(
      id: _settings!.id,
      predictionMode: predictionMode ?? _settings!.predictionMode,
      darkMode: darkMode ?? _settings!.darkMode,
      notificationEnabled: _settings!.notificationEnabled,
      notificationDaysBefore:
          notificationDaysBefore ?? _settings!.notificationDaysBefore,
      notificationTime: notificationTime ?? _settings!.notificationTime,
    );

    await _db.updateSettings(updatedSettings);
    _settings = updatedSettings;
    notifyListeners();
  }
}
