import 'dart:convert';

class EncryptionService {
  // TODO: Implement proper encryption, just base64 encoding for now

  /// Base64 string encode
  /// @param data string to be encoded.
  /// @returns The base64 encoded string.
  String base64Encode(String data) {
    final bytes = utf8.encode(data);
    return base64.encode(bytes);
  }
}
