<div align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="Logo" height="60">
  <h1 align="center">Period Tracker</h1>
</div>

<div>
  Period tracking mobile app I built for my girlfriend. She needed a simple app to track her period cycle without all the annoying ads and premium subscription offers. Requires no internet access, all data is stored on device.
</div>

## Features
- Effortless cycle logging with a clean, easy-to-use design
- Insights - average cycle and average period length
- Dynamic period prediction: smartly adjusts based on past cycles
- Static mode: set a fixed period & cycle duration for consistent tracking
- Customizable reminders: get notified n days before your period starts
- Offline data transfer between devices
- Easter eggs :)


## Download

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.lebaaar.period_tracker">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Google_Play_Store_badge_EN.svg/2560px-Google_Play_Store_badge_EN.svg.png" width="220" alt="Get it on Google Play">
  </a>
  <br>
  <br>
  <a href="download/app-release.apk">
    <img src="https://img.shields.io/badge/Download-APK-blue?logo=android&logoColor=white" width="220" alt="Download APK">
  </a>
  <br>
  <p align="center">
  <i>Available on Google Play Store and as a direct APK download. Not available on App Store because because f*ck Apple and their 99$/year membership</i>
  </p>
</p>



## Gallery
TODO

## Tech stack
Built entirely with Flutter, using multiple packages:
- `go_router` - navigation
- `provider` - state management
- `flutter_local_notifications` - local notifications
- `table_calendar` - interactivem customizable calendars
- `sqflite` - local database
- `shared_preferences` - lightweight key–value data persistence
- ...

## License
Distributed under the MIT License. See [LICENSE.txt](TODO).

## Privacy Policy
Available  [here](https://www.freeprivacypolicy.com/live/46902e6f-ed7c-4546-9990-e86785c11694).


## Contributing
Pull requests are always welcome! For major changes, please open an issue first to discuss the changes.

## Development

- Running release on device:
`flutter run --release`
- Building for release (make sure to update the version before each new release):
`flutter build appbundle --release`
- Running emulator via CLI:
`emulator -avd <AVD_NAME> -no-snapshot-save -no-boot-anim -gpu host -accel on`
