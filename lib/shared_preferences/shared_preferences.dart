import 'package:shared_preferences/shared_preferences.dart';

// onboarding_complete
Future<void> setOnboardingValue(bool isComplete) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', isComplete);
}

Future<bool> getOnboardingComplete() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}

// display_version_details
Future<void> setDisplayVersionDetailsValue(bool displayVersionDetails) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('display_version_details', displayVersionDetails);
}

Future<bool> getDisplayVersionDetails() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('display_version_details') ?? false;
}

// animal_generator_unlocked
Future<void> setAnimalGeneratorUnlockedValue(bool animalGeneratorUnlockedValue) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('animal_generator_unlocked', animalGeneratorUnlockedValue);
}

Future<bool> getAnimalGeneratorUnlocked() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('animal_generator_unlocked') ?? false;
}

// file_shared
Future<void> setFileShared(bool fileShared) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('file_shared', fileShared);
}

Future<bool?> getFileShared() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('file_shared');
}

Future<void> clearFileShared() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('file_shared');
}

// display_restore_success - isAfterRestore flag in code
Future<void> setDisplayRestoreSuccess(bool displayRestoreSuccess) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('display_restore_success', displayRestoreSuccess);
}

Future<bool> getDisplayRestoreSuccess() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('display_restore_success') ?? false;
}

Future<void> clearDisplayRestoreSuccess() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('display_restore_success');
}
