# Contributing to Period Tracker

Info about building, feedback webhook, testing and code structure.
<br>
Package id: `com.lebaaar.period_tracker`.

## Prerequisites

Please ensure you have Flutter 3+ (with Dart 3.8+) installed and working.

```bash
flutter pub get
cp .env.example .env   # optional: Discord webhook for Feedback
flutter build apk --debug --dart-define-from-file=.env && adb install -r build/app/outputs/flutter-apk/app-debug.apk
# or simply:
flutter run
```

## Tests

```bash
flutter analyze
flutter test
```

## Code structure

```
lib/pages/        screens (about, feedback, home, insights, restore, ...)
lib/widgets/      shared UI (sheets, buttons, grouped sections, ...)
lib/providers/    app state (periods, user, settings, theme)
lib/services/     database, notifications, backup, feedback
lib/models/       period, user, settings
```

## Releasing the app

Release builds must be signed with `android/key.properties` (see `android/example-key.properties` for structure).

1. Run `flutter analyze` and `flutter test`.
2. Bump `version:` in `pubspec.yaml`.
3. Make sure `.env` has the real webhook URL, then build:
   ```bash
   flutter build appbundle --release --dart-define-from-file=.env # build/app/outputs/bundle/release/app-release.aab, for Play
   ```
4. Install it on a phone and run through the app once. Uninstall any debug build first: different signing keys can't update each other, and uninstalling erases the app's data.
5. Play: Console → Production → *Create new release* → upload the `.aab`, add release notes and roll out.

## Tips

- Strange bugs: `flutter clean` followed by `flutter pub get`.
- Run an emulator from the CLI: `emulator -avd <AVD_NAME> -no-snapshot-save -no-boot-anim -gpu host -accel on`
