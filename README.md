<div align="center">
  <img src="images/logo.png" alt="Period Tracker icon" height="70">
  <h1 align="center">Period Tracker</h1>
</div>

<div>
  Period tracking mobile app I built for my girlfriend. She needed a simple app to track her period cycle without all the annoying ads and premium subscription offers. Requires no internet access, all data is stored on device.
</div>

## Features
- Effortless cycle logging with a clean, easy-to-use design
- Insights - average cycle and average period length
- Dynamic period prediction - smartly adjusts based on past cycles
- Static mode - set a fixed period & cycle duration for consistent tracking
- Customizable reminders - get notified n days before your period starts
- Offline data transfer between devices (for restoring data on a new device)
- Easter eggs :)

## Download

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.lebaaar.period_tracker" target="_blank">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Google_Play_Store_badge_EN.svg/2560px-Google_Play_Store_badge_EN.svg.png" width="220" alt="Get it on Google Play">
  </a>
  <br>
  <br>
  <a href="download/app-release.apk">
    <img src="https://img.shields.io/badge/Download-APK-blue?logo=android&logoColor=white" width="220" alt="Download APK">
  </a>
  <br>
  <p align="center">
    <i>Available on Google Play Store and as a direct APK download. Not available on App Store because because fuck Apple and their $99/year membership</i>
  </p>
</p>

## Gallery
<div align="center">
<img src="graphics/app/home.png" alt="Home page" width="200px">
<img src="graphics/app/insights.png" alt="Insights page" width="200px">
<img src="graphics/app/profile.png" alt="Profile page" width="200px">
<img src="graphics/app/restore.png" alt="Restore data page" width="200px">
</div>


## Legal
All data is stored locally on your device and is never transmitted. Complete privacy policy is available [here](https://www.freeprivacypolicy.com/live/46902e6f-ed7c-4546-9990-e86785c11694).

Distributed under the [MIT License](/LICENSE.txt).

## Development
Pull requests are always welcome! For major changes, please open an issue first to discuss the changes.

Period Tracker is built entirely with Flutter. To get started:
- Install Flutter 3 or higher and Android Studio (needed for Android emulator)
- Fork & clone the repository
- Install dependencies: `flutter pub get`
- Create a branch and name it like "*feature/issueId/short-desc*" for features or "*bugfix/issueId/short-desc*" for bugfixes.<br>
Eg: *feature/23/backup*
- Develop, test, commit, push (use descriptive commit messages)
- Open a pull request and name it like "*fix: #issueId - issueTitle*". <br>
Eg: *fix: #31 - Backup and restore data*<br>
Please provide a clear PR description

### Debug build
To run the app in debug mode use:<br>
`flutter run --debug`

### Release build
To run app in release mode you will need `android/key.properties` file. Structure of this file can be found in `example-key.properties` file.

To run the app in release mode run:<br>
`flutter run --release`

To prepare app for publishing run:<br>
`flutter build appbundle --release`

Make sure to update the version and build number before every release.

### Useful tips
- If you're encountering strange bugs, run `flutter clean` followed by `flutter pub get`
- Running emulator via CLI:
`emulator -avd <AVD_NAME> -no-snapshot-save -no-boot-anim -gpu host -accel on`
