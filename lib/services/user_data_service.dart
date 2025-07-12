import "package:path_provider/path_provider.dart";

class UserDataService {
  static final UserDataService _instance = UserDataService._constructor();

  factory UserDataService() {
    return _instance;
  }

  UserDataService._constructor();

  Future<String> getCacheDirectoryPath() async {
    final directory = await getApplicationCacheDirectory();
    return directory.path;
  }

  Future<void> clearAppData() async {
    final directory = await getApplicationCacheDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true); // Recreate the directory
  }
}
