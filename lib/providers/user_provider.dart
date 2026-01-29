import 'package:flutter/material.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/services/database_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  final DatabaseService _db = DatabaseService();

  UserProvider() {
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      _user = await _db.getUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user: $e');
      _user = null;
      notifyListeners();
    }
  }

  Future<void> updateUser({
    int? id,
    String? name,
    required int cycleLength,
    required int periodLength,
    String? partnerPhoneNumber,
    String? partnerMessageHeading,
  }) async {
    try {
      final User updatedUser = User(
        id: 1,
        name: name ?? _user?.name,
        cycleLength: cycleLength,
        periodLength: periodLength,
        partnerPhoneNumber: partnerPhoneNumber ?? _user?.partnerPhoneNumber,
        partnerMessageHeading: partnerMessageHeading ?? _user?.partnerMessageHeading,
      );
      _user = updatedUser;
      await _db.insertUser(_user!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> insertUser(User user) async {
    await _db.insertUser(user);
    _user = user;
    notifyListeners();
  }
}
