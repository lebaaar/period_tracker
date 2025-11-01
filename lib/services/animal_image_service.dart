import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:period_tracker/enums/dog_breed.dart';

class AnimalImageService {
  /// Fetches a random cat image from the Cat API (not used)
  /// @returns The URL of the random cat image.
  Future<String> getRandomCatImage() async {
    final String url = 'https://api.thecatapi.com/v1/images/search';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['url'];
    } else {
      throw Exception('Failed to fetch image');
    }
  }

  /// Fetches a random dog image from the Dog API.
  /// @param dog The breed of the dog.
  /// @returns The URL of the random dog image.
  Future<String> getRandomDogImage(DogBreed dog) async {
    final String url = 'https://dog.ceo/api/breed/${dog.value}/images/random';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw Exception('Failed to fetch image');
    }
  }
}
