import 'dart:io';

class FileHelper {
  static Future<String?> readFileContent(String filePath) async {
    if (filePath.isEmpty) {
      return null;
    }

    // check if file exists
    final File fileToCheck = File(filePath);
    if (!await fileToCheck.exists()) {
      return null;
    }

    final File file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final String fileContent = await file.readAsString();
    return fileContent;
  }
}
