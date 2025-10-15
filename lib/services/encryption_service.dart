import 'dart:convert';

class EncryptionService {
  // TODO: Implement proper encryption, just base64 encoding for now
  String base64Encode(String data) {
    final bytes = utf8.encode(data);
    return base64.encode(bytes);
  }
}
