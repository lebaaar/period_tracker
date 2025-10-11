import "dart:io";
import "package:package_info_plus/package_info_plus.dart";
import "package:path_provider/path_provider.dart";
import "package:period_tracker/constants.dart";
import "package:period_tracker/models/period_model.dart";
import "package:period_tracker/models/settings_model.dart";
import "package:period_tracker/models/user_model.dart";
import "package:period_tracker/services/database_service.dart";
import "package:period_tracker/shared_preferences/shared_preferences.dart";
import "package:share_plus/share_plus.dart";
import "package:shared_preferences/shared_preferences.dart";

class ApplicationDataService {
  static final ApplicationDataService _instance =
      ApplicationDataService._constructor();

  factory ApplicationDataService() {
    return _instance;
  }

  ApplicationDataService._constructor();

  Future<String> getCacheDirectoryPath() async {
    final directory = await getApplicationCacheDirectory();
    return directory.path;
  }

  Future<void> clearAppData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await DatabaseService().truncateDatabaseTables();
    setOnboardingValue(false);
    final directory = await getApplicationCacheDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);
  }

  Future<bool> shareBackup(XFile file) async {
    final params = ShareParams(
      subject: kBackupEmailTitle,
      text: kBackupEmailText,
      files: [file],
    );

    final result = await SharePlus.instance.share(params);
    if (result.status == ShareResultStatus.success) {
      return true;
    }
    return false;
  }

  // Future<bool> requestStoragePermission() async {
  //   var status = await Permission.storage.status;
  //   if (!status.isGranted) {
  //     status = await Permission.storage.request();
  //   }
  //   return status.isGranted;
  // }

  /// Creates a backup of all app data including database and shared preferences
  Future<String> createBackupFileContent() async {
    // TODO
    final databaseService = DatabaseService();
    final prefs = await SharedPreferences.getInstance();

    // Get all data from database
    final periods = await databaseService.getAllPeriods();
    final user = await databaseService.getUser();
    final settings = await databaseService.getSettings();

    // Get all shared preferences data
    final sharedPrefsData = <String, dynamic>{};
    final keys = prefs.getKeys();
    for (String key in keys) {
      final value = prefs.get(key);
      sharedPrefsData[key] = value;
    }

    // Create backup data structure
    final backupData = {
      'version': await PackageInfo.fromPlatform().then((info) => info.version),
      'timestamp': DateTime.now().toIso8601String(),
      'database': {
        'periods': periods.map((period) => period.toMap()).toList(),
        'user': user?.toMap(),
        'settings': settings.toMap(),
      },
      'sharedPreferences': sharedPrefsData,
    };

    return backupData.toString();
  }

  /// Exports backup data to a JSON file
  Future<XFile> exportBackupToFile(String backupContent) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$kBackupFileName';
    final File file = File(filePath);
    await file.writeAsString(backupContent);

    return XFile(filePath);
  }

  /// Restores app data from backup data
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    // TODO
    // Validate backup data structure
    if (!_isValidBackupData(backupData)) {
      throw Exception('Invalid backup data format');
    }

    final databaseService = DatabaseService();
    final prefs = await SharedPreferences.getInstance();

    try {
      // Clear existing data
      await clearAppData();

      // Restore database data
      final databaseData = backupData['database'] as Map<String, dynamic>;

      // Restore user data
      if (databaseData['user'] != null) {
        await databaseService.insertUser(
          User.fromMap(databaseData['user'] as Map<String, dynamic>),
        );
      }

      // Restore settings data
      if (databaseData['settings'] != null) {
        await databaseService.updateSettings(
          Settings.fromMap(databaseData['settings'] as Map<String, dynamic>),
        );
      }

      // Restore periods data
      if (databaseData['periods'] != null) {
        final periodsList = databaseData['periods'] as List<dynamic>;
        for (var periodMap in periodsList) {
          final period = Period.fromMap(periodMap as Map<String, dynamic>);
          await databaseService.insertPeriod(period);
        }
      }

      // Restore shared preferences
      if (backupData['sharedPreferences'] != null) {
        final sharedPrefsData =
            backupData['sharedPreferences'] as Map<String, dynamic>;
        for (var entry in sharedPrefsData.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is List<String>) {
            await prefs.setStringList(key, value);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }

  /// Validates the backup data structure
  bool _isValidBackupData(Map<String, dynamic> data) {
    // TODO
    return data.containsKey('version') &&
        data.containsKey('timestamp') &&
        data.containsKey('database') &&
        data.containsKey('sharedPreferences');
  }
}
