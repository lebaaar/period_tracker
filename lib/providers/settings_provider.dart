import 'package:flutter/material.dart';
import 'package:period_tracker/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _notificationEnabled = false;
  bool get notificationEnabled => _notificationEnabled;
  final DatabaseService _db = DatabaseService();

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final enabled = await _db.getNotificationEnabled();
    _notificationEnabled = enabled;
    notifyListeners();
  }

  Future<void> toggleNotificationEnabled(bool enabled) async {
    await _db.updateNotificationEnabled(enabled);
    _notificationEnabled = enabled;
    notifyListeners();
  }
}
