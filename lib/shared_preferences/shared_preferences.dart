import 'package:shared_preferences/shared_preferences.dart';

Future<void> setOnboardingValue(bool isComplete) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', isComplete);
}

Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}
