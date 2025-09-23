import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/services/cat_image_service.dart';

class CatGeneratorPage extends StatefulWidget {
  const CatGeneratorPage({super.key});

  @override
  State<CatGeneratorPage> createState() => _CatGeneratorPageState();
}

class _CatGeneratorPageState extends State<CatGeneratorPage> {
  String? catImageUrl;
  bool isLoadingCatImage = false;

  Future<void> fetchCatImage() async {
    setState(() => isLoadingCatImage = true);
    try {
      final url = await CatImageService().getRandomCatImage();
      setState(() {
        catImageUrl = url;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load cat image, please try again later.'),
        ),
      );
    } finally {
      setState(() => isLoadingCatImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCatImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cat Generator',
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
        child: Center(
          child: isLoadingCatImage
              ? const CircularProgressIndicator()
              : (catImageUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Good kitty! 🐱'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(kBorderRadius),
                            child: Image.network(
                              catImageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, size: 80),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: fetchCatImage,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
              ),
              child: const Text('Next cat'),
            ),
          ),
        ),
      ),
    );
  }
}
