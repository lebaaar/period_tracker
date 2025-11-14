import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_mail/open_mail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/dog_breed.dart';
import 'package:period_tracker/services/animal_image_service.dart';

class AnimalGeneratorPage extends StatefulWidget {
  const AnimalGeneratorPage({super.key});

  @override
  State<AnimalGeneratorPage> createState() => _AnimalGeneratorPageState();
}

class _AnimalGeneratorPageState extends State<AnimalGeneratorPage> {
  String? _imageUrl;
  bool _isLoadingImage = false;
  DogBreed _selectedDogBreed = DogBreed.doberman;
  bool _displayError = false;

  Future<void> fetchImage(DogBreed dogBreed) async {
    setState(() => _isLoadingImage = true);
    try {
      final url = await AnimalImageService().getRandomDogImage(dogBreed);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _displayError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _displayError = true;
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> openEmail() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final EmailContent emailContent = EmailContent(
      to: [kContactEmail],
      subject: 'Issue with Period Tracker',
      body:
          '''
Hello,

I'm having an issue with fetching doggy images in the Period Tracker app.

[Timestamp: ${DateTime.now()}]
[Version: ${packageInfo.version}+${packageInfo.buildNumber}]
[Device: ${Platform.operatingSystem}]
[OS version: ${Platform.operatingSystemVersion}]''',
    );
    final OpenMailAppResult result;

    try {
      result = await OpenMail.composeNewEmailInMailApp(nativePickerTitle: 'Select email app to contact support', emailContent: emailContent);

      if (!result.didOpen && !result.canOpen) {
        showNoMailAppsDialog(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('An error occurred while trying to open email app'), behavior: SnackBarBehavior.floating));
    }
  }

  void showNoMailAppsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cannot Open Email App"),
          content: const Text("No email apps installed on this device. Please install an email app to contact support."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchImage(_selectedDogBreed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Doggy Generator', style: Theme.of(context).textTheme.titleMedium),
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
                decoration: const InputDecoration(labelText: 'Select Dog Breed', border: OutlineInputBorder()),
                initialValue: _selectedDogBreed,
                items: DogBreed.values.map((breed) {
                  return DropdownMenuItem<DogBreed>(value: breed, child: Text(breed.display));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDogBreed = value;
                    });
                    fetchImage(value);
                  }
                },
              ),
            ),
            Expanded(
              child: Center(
                child: _isLoadingImage
                    ? const CircularProgressIndicator()
                    : _displayError
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Failed to fetch doggy image :(',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Make sure you are connected to the internet and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('If the issue persists ', style: Theme.of(context).textTheme.bodyMedium),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  onPressed: () => openEmail(),
                                  child: Text(
                                    'contact support',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Theme.of(context).colorScheme.onSurface,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text('.'),
                              ],
                            ),
                          ],
                        ),
                      )
                    : (_imageUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(const SnackBar(content: Text('Good doggy! 🐶'), behavior: SnackBarBehavior.floating));
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(kBorderRadius),
                                  child: Image.network(
                                    _imageUrl!,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 80),
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
                fetchImage(_selectedDogBreed);
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
              ),
              child: const Text('Next doggy'),
            ),
          ),
        ),
      ),
    );
  }
}
