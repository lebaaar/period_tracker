import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';

class RestoreDataPreviewPage extends StatefulWidget {
  const RestoreDataPreviewPage({super.key});

  @override
  State<RestoreDataPreviewPage> createState() => _RestoreDataPreviewPageState();
}

class _RestoreDataPreviewPageState extends State<RestoreDataPreviewPage> {
  late bool _onBoardingComplete;
  String? _sharedFilePath;
  String? _sharedFileContent;
  String? _name;
  bool _loading = true;
  String? _error;
  bool _showErrorDetails = false;
  bool _alertShown = false;

  Future<void> _initialize() async {
    final isComplete = await getOnboardingComplete();
    setState(() {
      _onBoardingComplete = isComplete;
    });

    try {
      // setState(() {
      //   _loading = false;
      //   _sharedFilePath =
      //       '/data/user/0/com.example.period_tracker/cache/data (4).period';
      // });
      // return;

      final String? path = await getSharedFilePath();
      await setSharedFilePath(''); // clear the shared file path after use
      if (path == null || path.isEmpty) {
        setState(() {
          _sharedFilePath = null;
          _sharedFileContent = null;
          _loading = false;
        });
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _sharedFilePath = path;
          _sharedFileContent = null;
          _loading = false;
          _error = 'Shared file not found on disk';
        });
        return;
      }

      final content = await file.readAsString();
      setState(() {
        _sharedFilePath = path;
        _sharedFileContent = content;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeShowOnboardingAlert(),
      );
    } catch (e) {
      setState(() {
        _sharedFilePath = null;
        _sharedFileContent = null;
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _maybeShowOnboardingAlert() {
    if (!mounted) return;
    if (_alertShown) return;
    if (_onBoardingComplete && _sharedFilePath != null) {
      _alertShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Existing data detected'),
          content: const Text(
            'We detected you already have an existing account on this device. Restoring from this backup will replace your current data.\n'
            'Do you wish to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(_onBoardingComplete ? '/' : '/onboarding');
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_error != null || _sharedFilePath == null)
                      Column(
                        children: [
                          Text(
                            'Error :(',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'There might be an issue with your $kBackupFileName file.\nTry exporting the file again, by clicking "Transfer data" in the Profile section of the app on your old phone. Then open the new file with this app to restore your data.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.fontSize,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.go(
                                _onBoardingComplete ? '/' : '/onboarding',
                              );
                            },
                            child: Text('Exit restore'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => setState(
                              () => _showErrorDetails = !_showErrorDetails,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _showErrorDetails
                                      ? 'Hide details'
                                      : 'Show details',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                    fontSize: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.fontSize,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _showErrorDetails
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(
                                _error ?? 'Unknown error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontSize: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.fontSize,
                                ),
                              ),
                            ),
                            crossFadeState: _showErrorDetails
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),

                    if (_sharedFilePath != null)
                      Column(
                        children: [
                          SizedBox(height: 30),
                          if (_onBoardingComplete)
                            Column(
                              children: [
                                Text(
                                  _name == null || _name!.isEmpty
                                      ? 'Welcome!'
                                      : 'Welcome $_name!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    right: 8.0,
                                  ),
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    'You opened a $kBackupFileName file, which means your existing data will be replaced with the data in the backup file. This action cannot be undone.',
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    context.go('/onboarding');
                                  },
                                  child: const Text('Restore from file'),
                                ),
                                const SizedBox(height: 40),
                                const Text('Want to keep your existing data?'),
                                ElevatedButton(
                                  onPressed: () {
                                    context.go('/');
                                  },
                                  child: const Text('Go back home'),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Text(
                                  _name == null || _name!.isEmpty
                                      ? 'Welcome back!'
                                      : 'Welcome back $_name!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All your n logged periods and notes are ready to be restored.',
                                  textAlign: TextAlign.center,
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Restore my data'),
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Want to start fresh instead?',
                                  textAlign: TextAlign.center,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    context.go('/onboarding');
                                  },
                                  child: const Text('Start fresh'),
                                ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
