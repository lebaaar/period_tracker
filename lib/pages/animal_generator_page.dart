import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/dog_breed.dart';
import 'package:period_tracker/enums/feedback_type.dart';
import 'package:period_tracker/pages/feedback_page.dart';
import 'package:period_tracker/services/animal_image_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/primary_button.dart';

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

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void openFeedback() {
    context.push(
      '/feedback',
      extra: const FeedbackArgs(type: FeedbackType.bugReport, errorCode: kDogApiErrorCode),
    );
  }

  Future<void> _pickBreed() async {
    final DogBreed? picked = await showSelectSheet<DogBreed>(
      context: context,
      title: 'Breed',
      selected: _selectedDogBreed,
      options: [for (final DogBreed b in DogBreed.values) SelectOption(value: b, label: b.display)],
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDogBreed = picked);
    fetchImage(picked);
  }

  @override
  void initState() {
    super.initState();
    fetchImage(_selectedDogBreed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LargeTitleScaffold(
      title: 'Doggy generator',
      largeTitle: false,
      bottom: PrimaryButton(label: 'Next doggy', onPressed: _isLoadingImage ? null : () => fetchImage(_selectedDogBreed)),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Pressable(
              onTap: _pickBreed,
              pressedScale: 0.985,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.pets_rounded, size: 20, color: c.labelSecondary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_selectedDogBreed.display, style: context.text.bodyLarge)),
                    Icon(Icons.unfold_more_rounded, size: 22, color: c.labelTertiary),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isLoadingImage
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 360,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _displayError
                  ? Padding(
                      key: const ValueKey('error'),
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
                      child: Column(
                        children: [
                          Text('Couldn\'t fetch a doggy :(', textAlign: TextAlign.center, style: context.text.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Check your internet connection and try again.',
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium?.copyWith(color: c.labelSecondary),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(label: 'Report this issue', expand: false, style: AppButtonStyle.secondary, onPressed: openFeedback),
                        ],
                      ),
                    )
                  : (_imageUrl != null
                        ? GestureDetector(
                            key: ValueKey(_imageUrl),
                            onTap: () => _snack('Good doggy! 🐶'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                _imageUrl!,
                                height: 360,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null ? child : const SizedBox(height: 360, child: Center(child: CircularProgressIndicator())),
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(height: 360, child: Center(child: Icon(Icons.error_outline_rounded, size: 48))),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
            ),
          ),
        ),
      ],
    );
  }
}
