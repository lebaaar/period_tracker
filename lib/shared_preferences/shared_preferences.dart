import 'package:shared_preferences/shared_preferences.dart';

// onboarding_complete
Future<void> setOnboardingValue(bool isComplete) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', isComplete);
}

Future<bool> getOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}

// display_version_details
Future<void> setDisplayVersionDetailsValue(bool displayVersionDetails) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('display_version_details', displayVersionDetails);
}

Future<bool> getDisplayVersionDetails() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('display_version_details') ?? false;
}

// animal_generator_unlocked
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

// shared_file_path
Future<void> setSharedFilePath(String filePath) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('shared_file_path', filePath);
}

Future<String?> getSharedFilePath() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('shared_file_path');
}

Future<void> clearSharedFilePath() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('shared_file_path');
}

// display_restore_success
Future<void> setDisplayRestoreSuccess(bool displayRestoreSuccess) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('display_restore_success', displayRestoreSuccess);
}

Future<bool> getDisplayRestoreSuccess() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('display_restore_success') ?? false;
}

Future<void> clearDisplayRestoreSuccess() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('display_restore_success');
}
