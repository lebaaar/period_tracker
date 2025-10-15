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

  /// Restores app data from backup data
  /// @param backupData The Map representation of the backup data
  /// @throws Exception if the backup data is invalid or restoration fails
  Future<void> restoreFromBackup(Map<String, dynamic> backupData) async {
    // TODO
    // Validate backup data structure
    if (!isBackupDataValid(backupData)) {
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
  /// @param data The Map representation of the backup data
  /// @returns true if the backup data structure is valid, false otherwise
  bool isBackupDataValid(Map<String, dynamic> data) {
    // TODO
    final requiredKeys = {
      'version',
      'timestamp',
      'database',
      'sharedPreferences',
    };
    for (var key in requiredKeys) {
      if (!data.containsKey(key)) {
        return false;
      }
    }

    final dbContent = data['database'];
    if (dbContent is! Map<String, dynamic>) return false;

    final dbRequiredKeys = {'periods', 'user', 'settings'};
    for (var key in dbRequiredKeys) {
      if (!dbContent.containsKey(key)) {
        return false;
      }
    }

    return true;
  }
}
