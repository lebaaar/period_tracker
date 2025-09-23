import 'dart:convert';
import 'package:http/http.dart' as http;

class CatImageService {
  static const String _baseUrl = 'https://api.thecatapi.com/v1/images/search';

  Future<String> getRandomCatImage() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['url'];
    } else {
      throw Exception('Failed to fetch cat image');
    }
  }
}
