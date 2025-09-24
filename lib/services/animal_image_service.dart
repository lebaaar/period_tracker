import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:period_tracker/enums/dog_breed.dart';

class AnimalImageService {
  Future<String> getRandomCatImage() async {
    String url = 'https://api.thecatapi.com/v1/images/search';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['url'];
    } else {
      throw Exception('Failed to fetch image');
    }
  }

  Future<String> getRandomDogImage(DogBreed dog) async {
    String url = 'https://dog.ceo/api/breed/${dog.value}/images/random';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw Exception('Failed to fetch image');
    }
  }
}
