import "package:path_provider/path_provider.dart";
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
    final directory = await getApplicationCacheDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true); // Recreate the directory
  }
}
