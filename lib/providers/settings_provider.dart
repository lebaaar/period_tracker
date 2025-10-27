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
  Future<void> setNotificationEnabled(bool value) async {
    if (_settings == null) return;
    await _db.updateNotificationEnabled(value);
    _settings = Settings(
      id: _settings!.id,
      predictionMode: _settings!.predictionMode,
      darkMode: _settings!.darkMode,
      notificationsEnabled: value,
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
      notificationsEnabled: _settings!.notificationsEnabled,
      notificationDaysBefore: _settings!.notificationDaysBefore,
      notificationTime: _settings!.notificationTime,
    );
    await _db.updateSettings(_settings!);
    notifyListeners();
  }

  Future<void> insertSettings(Settings settings) async {
    await _db.insertSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  Future<void> updateSettings({
    String? predictionMode,
    bool? darkMode,
    bool? notificationsEnabled,
    int? notificationDaysBefore,
    TimeOfDay? notificationTime,
  }) async {
    if (_settings == null) return;

    final updatedSettings = Settings(
      id: _settings!.id,
      predictionMode: predictionMode ?? _settings!.predictionMode,
      darkMode: darkMode ?? _settings!.darkMode,
      notificationsEnabled:
          notificationsEnabled ?? _settings!.notificationsEnabled,
      notificationDaysBefore:
          notificationDaysBefore ?? _settings!.notificationDaysBefore,
      notificationTime: notificationTime ?? _settings!.notificationTime,
    );

    await _db.updateSettings(updatedSettings);
    _settings = updatedSettings;
    notifyListeners();
  }
}
