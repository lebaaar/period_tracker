import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/dog_breed.dart';
import 'package:period_tracker/services/animal_image_service.dart';

class AnimalGeneratorPage extends StatefulWidget {
  const AnimalGeneratorPage({super.key});

  @override
  State<AnimalGeneratorPage> createState() => _AnimalGeneratorPageState();
}

class _AnimalGeneratorPageState extends State<AnimalGeneratorPage> {
  String? imageUrl;
  bool isLoadingImage = false;
  DogBreed selectedDogBreed = DogBreed.doberman;
  bool displayError = false;

  Future<void> fetchImage(DogBreed dogBreed) async {
    setState(() => isLoadingImage = true);
    try {
      final url = await AnimalImageService().getRandomDogImage(dogBreed);
      setState(() {
        imageUrl = url;
        displayError = false;
      });
    } catch (e) {
      setState(() {
        displayError = true;
      });
    } finally {
      setState(() {
        isLoadingImage = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchImage(selectedDogBreed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Doggy Generator',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<DogBreed>(
                decoration: const InputDecoration(
                  labelText: 'Select Dog Breed',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedDogBreed,
                items: DogBreed.values.map((breed) {
                  return DropdownMenuItem<DogBreed>(
                    value: breed,
                    child: Text(breed.display),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDogBreed = value;
                    });
                    fetchImage(value);
                  }
                },
              ),
            ),
            Expanded(
              child: Center(
                child: isLoadingImage
                    ? const CircularProgressIndicator()
                    : displayError
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Failed to fetch doggy image 😢',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Make sure you are connected to the internet and try again. If the issue persists, there might be a problem with the API.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.fontSize,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (imageUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Good boy! 🐶'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    kBorderRadius,
                                  ),
                                  child: Image.network(
                                    imageUrl!,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error, size: 80),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Use the enum value directly for API call (its .name is used in the service)
                fetchImage(selectedDogBreed);
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
              ),
              child: const Text('Next doggy'),
            ),
          ),
        ),
      ),
    );
  }
}
