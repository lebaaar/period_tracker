import "dart:convert";
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

  /// Clears all app data including database and shared preferences
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

  /// Shares the backup file using the platform's share mechanism
  /// @param file The XFile object representing the backup file to be shared
  /// @returns true if sharing was successful, false otherwise
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

  /// Creates a JSON string containing all app data for backup
  /// @returns JSON string representing the backup data
  Future<String> createBackupFileContent() async {
    // Get all data from database
    final databaseService = DatabaseService();
    final periods = await databaseService.getAllPeriods();
    final user = await databaseService.getUser();
    final settings = await databaseService.getSettings();

    // Get all shared preferences data
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final sharedPrefsData = <String, dynamic>{};
    for (String key in keys) {
      final value = prefs.get(key);
      sharedPrefsData[key] = value;
    }

    final Map<String, dynamic> backupData = {
      'version': (await PackageInfo.fromPlatform()).version,
      'buildNumber': (await PackageInfo.fromPlatform()).buildNumber,
      'timestamp': DateTime.now().toIso8601String(),
      'database': {
        'periods': periods.map((period) => period.toMap()).toList(),
        'user': user?.toMap(),
        'settings': settings.toMap(),
      },
      'sharedPreferences': sharedPrefsData,
    };
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(backupData);

    return jsonString;
  }

  /// Exports backup data to a .json file with application/json MIME format and returns the file
  /// @param backupContent The JSON string content to be written to the file
  /// @returns XFile object representing the backup file
  Future<XFile> exportBackupToFile(String backupContent) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$kBackupFileName';
    final File file = File(filePath);
    await file.writeAsString(backupContent);

    return XFile(filePath, mimeType: 'application/json');
  }

  /// Parses the backup file content and returns a Map representation
  /// @param content The JSON string content of the backup file
  /// @returns Map representing the backup data
  Map<String, dynamic> parseBackupFile(String content) {
    final Map<String, dynamic> data = jsonDecode(content);
    return data;
  }

  /// Restores app data from backup data. Data is always validated before calling this method.
  /// @param backupData The Map representation of the backup data
  /// @throws Exception if the backup data is invalid or restoration fails
  Future<bool> restoreFromBackup(Map<String, dynamic> backupData) async {
    final databaseService = DatabaseService();

    try {
      // Clear existing data
      await clearAppData();

      // Load database data
      final Map<String, dynamic> database = backupData['database'];
      final User user = User.fromMap(database['user'] as Map<String, dynamic>);
      final Settings settings = Settings.fromMap(
        database['settings'] as Map<String, dynamic>,
      );
      final List<dynamic> periodsList = database['periods'] as List<dynamic>;
      final List<Period> periods = periodsList
          .map((periodMap) => Period.fromMap(periodMap as Map<String, dynamic>))
          .toList();

      // Restore user data
      await databaseService.insertUser(user);

      // Restore settings data
      await databaseService.updateSettings(settings);

      // Restore periods data
      for (var period in periods) {
        await databaseService.insertPeriod(period);
      }

      // Restore shared preferences data
      final Map<String, dynamic> sharedPrefsData =
          backupData['sharedPreferences'] as Map<String, dynamic>;

      if (backupData['sharedPreferences'] == null) {
        return true;
      }

      for (var entry in sharedPrefsData.entries) {
        final key = entry.key;
        final value = entry.value;
        switch (key) {
          case 'onboarding_complete':
            setOnboardingValue(value as bool);
            break;
          case 'notifications_enabled':
            setNotificationsValue(value as bool);
            break;
          case 'display_version_details':
            setDisplayVersionDetailsValue(value as bool);
            break;
          case 'animal_generator_unlocked':
            setAnimalGeneratorUnlockedValue(value as bool);
            break;
          case 'shared_file_path':
            // skip
            break;
          default:
            continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to restore from backup: $e');
    }

    return true;
  }

  /// Validates the backup data structure
  /// @param data The Map representation of the backup data
  /// @returns true if the backup data structure is valid, false otherwise
  bool isBackupDataValid(Map<String, dynamic> data) {
    final requiredKeys = {
      'version',
      'buildNumber',
      'timestamp',
      'database',
      'sharedPreferences',
    };
    for (String key in requiredKeys) {
      if (!data.containsKey(key)) {
        return false;
      }
    }

    final dbContent = data['database'];
    if (dbContent is! Map<String, dynamic>) return false;

    final dbRequiredKeys = {'periods', 'user', 'settings'};
    for (String key in dbRequiredKeys) {
      if (!dbContent.containsKey(key)) {
        return false;
      }
    }

    // try parsing periods
    final periods = dbContent['periods'];
    if (periods is! List<dynamic>) return false;
    for (var period in periods) {
      if (period is! Map<String, dynamic>) return false;
      try {
        Period.fromMap(period);
      } catch (e) {
        return false;
      }
    }

    // try parsing user
    final user = dbContent['user'];
    if (user != null) {
      if (user is! Map<String, dynamic>) return false;
      try {
        User.fromMap(user);
      } catch (e) {
        return false;
      }
    }

    // try parsing settings
    final settings = dbContent['settings'];
    if (settings is! Map<String, dynamic>) return false;
    try {
      Settings.fromMap(settings);
    } catch (e) {
      return false;
    }

    return true;
  }

  /// Verifies if the backup file version is compatible with the current app version
  /// @param backupVersion The version string from the backup file
  /// @param currentVersion The current app version string
  /// @returns true if the versions are compatible, false otherwise
  bool verifyVersionCompatibility(String backupVersion, String currentVersion) {
    // TODO: Implement in case of breaking DB changes in future versions
    return true;
  }
}
