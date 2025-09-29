import 'package:shared_preferences/shared_preferences.dart';

// Onboarding complete
Future<void> setOnboardingValue(bool isComplete) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', isComplete);
}

Future<bool> getOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}

// Notification enabled
Future<void> setNotificationsValue(bool notificationsEnabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('notifications_enabled', notificationsEnabled);
}

Future<bool> getNotificationEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('notifications_enabled') ?? true;
}

// Display version details
Future<void> setDisplayVersionDetailsValue(bool displayVersionDetails) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('display_version_details', displayVersionDetails);
}

Future<bool> getDisplayVersionDetails() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('display_version_details') ?? false;
}
