import "package:path_provider/path_provider.dart";
import "package:period_tracker/services/database_service.dart";
import "package:period_tracker/shared_preferences/shared_preferences.dart";
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
}
