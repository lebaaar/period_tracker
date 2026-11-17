import 'package:flutter/foundation.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';

/// Hidden-feature flags (doggy generator, Order boyfriend, "made with love" line).
/// Kept in a provider so unlocking shows up everywhere immediately.
class UnlocksProvider extends ChangeNotifier {
  bool _animalGenerator;
  bool _versionDetails;

  UnlocksProvider(this._animalGenerator, this._versionDetails);

  static Future<UnlocksProvider> load() async => UnlocksProvider(await getAnimalGeneratorUnlocked(), await getDisplayVersionDetails());

  bool get animalGenerator => _animalGenerator;
  bool get versionDetails => _versionDetails;

  /// "Order boyfriend" needs both unlocks.
  bool get orderBoyfriend => _animalGenerator && _versionDetails;

  Future<void> setAnimalGenerator(bool value) async {
    if (value == _animalGenerator) return;
    _animalGenerator = value;
    notifyListeners();
    await setAnimalGeneratorUnlockedValue(value);
  }

  Future<void> setVersionDetails(bool value) async {
    if (value == _versionDetails) return;
    _versionDetails = value;
    notifyListeners();
    await setDisplayVersionDetailsValue(value);
  }

  /// Re-reads preferences after they were cleared.
  Future<void> reload() async {
    _animalGenerator = await getAnimalGeneratorUnlocked();
    _versionDetails = await getDisplayVersionDetails();
    notifyListeners();
  }
}
