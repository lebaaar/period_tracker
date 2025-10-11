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

// Animal generator unlocked
Future<void> setAnimalGeneratorUnlockedValue(
  bool animalGeneratorUnlockedValue,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(
    'animal_generator_unlocked',
    animalGeneratorUnlockedValue,
  );
}

Future<bool> getAnimalGeneratorUnlocked() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('animal_generator_unlocked') ?? false;
}

Future<void> setSharedFilePath(String filePath) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('shared_file_path', filePath);
}

Future<String?> getSharedFilePath() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('shared_file_path');
}
