import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('unlocking notifies listeners right away and persists', () async {
    final UnlocksProvider unlocks = await UnlocksProvider.load();
    int notified = 0;
    unlocks.addListener(() => notified++);

    expect(unlocks.animalGenerator, isFalse);
    expect(unlocks.orderBoyfriend, isFalse);

    final Future<void> pending = unlocks.setAnimalGenerator(true);
    // state flips synchronously, before the preference write completes
    expect(unlocks.animalGenerator, isTrue);
    expect(notified, 1);
    await pending;

    // order boyfriend needs both flags
    expect(unlocks.orderBoyfriend, isFalse);
    await unlocks.setVersionDetails(true);
    expect(unlocks.orderBoyfriend, isTrue);
    expect(notified, 2);

    // survives a restart
    final UnlocksProvider reloaded = await UnlocksProvider.load();
    expect(reloaded.orderBoyfriend, isTrue);
  });

  test('reload picks up cleared preferences (account deleted)', () async {
    final UnlocksProvider unlocks = await UnlocksProvider.load();
    await unlocks.setAnimalGenerator(true);
    await unlocks.setVersionDetails(true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await unlocks.reload();

    expect(unlocks.animalGenerator, isFalse);
    expect(unlocks.orderBoyfriend, isFalse);
  });
}
