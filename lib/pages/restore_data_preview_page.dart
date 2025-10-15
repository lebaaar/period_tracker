import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_mail/open_mail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/encryption_service.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';

class RestoreDataPreviewPage extends StatefulWidget {
  const RestoreDataPreviewPage({super.key});

  @override
  State<RestoreDataPreviewPage> createState() => _RestoreDataPreviewPageState();
}

class _RestoreDataPreviewPageState extends State<RestoreDataPreviewPage> {
  late bool _onBoardingComplete;
  String? _sharedFilePath;
  Map<String, dynamic>? _sharedFileContent;
  bool _loading = true;
  String? _error;
  bool _showErrorDetails = false;
  bool _alertShown = false;

  String? _name;
  List<Period> _periods = [];

  Future<void> _initialize() async {
    final isComplete = await getOnboardingComplete();
    setState(() {
      _onBoardingComplete = isComplete;
    });

    try {
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
      final String fileContent = await file.readAsString();
      _sharedFileContent = ApplicationDataService().parseBackupFile(
        fileContent,
      );
      if (_sharedFileContent == null) {
        setState(() {
          _sharedFilePath = path;
          _sharedFileContent = null;
          _loading = false;
          _error = 'Failed to parse backup file';
        });
        return;
      }

      // verify backup data structure and content
      final bool valid = ApplicationDataService().isBackupDataValid(
        _sharedFileContent!,
      );
      if (!valid) {
        setState(() {
          _sharedFilePath = path;
          _sharedFileContent = null;
          _loading = false;
          _error = 'Invalid backup file format';
        });
        return;
      }

      setState(() {
        _sharedFilePath = path;
        _sharedFileContent = _sharedFileContent!;
        _loading = false;
        _name = _sharedFileContent!['database']['user']['name'];
        _periods = (_sharedFileContent!['database']['periods'] as List<dynamic>)
            .map((e) => Period.fromMap(e as Map<String, dynamic>))
            .toList();
      });

      setState(() {
        _error = 'KYS';
      });

      // show alert if onboarding is complete and we have a valid shared file
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
            'We detected you already have an existing account on this device. Restoring from this backup file will replace your current data.\n'
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

  void _restoreData() {
    //
    if (_sharedFileContent == null) return;
    ApplicationDataService().restoreFromBackup(_sharedFileContent!);
    context.go('/');
  }

  void showNoMailAppsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cannot Open Email App"),
          content: const Text(
            "No email apps installed on this device. Please install an email app to contact support.",
          ),
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

  Future<void> openEmail() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // TODO - AES encrypt the content
    final String encodedContent = _sharedFileContent != null
        ? EncryptionService().base64Encode(_sharedFileContent.toString())
        : 'N/A';

    final EmailContent emailContent = EmailContent(
      to: [kContactEmail],
      subject: 'Issue with Period Tracker [$kRestoreDataErrorCode]',
      body:
          '''
Hello,
I'm having an issue with restoring data in the Period Tracker app.
Here are the details:\n
[Error: ${_error ?? 'Unknown error'}]
[Timestamp: ${DateTime.now()}]
[Version: ${packageInfo.version}+${packageInfo.buildNumber}]
[Device: ${Platform.operatingSystem}]
[OS version: ${Platform.operatingSystemVersion}]
[Backup path: ${_sharedFilePath ?? 'N/A'}]
[Backup content:
$encodedContent]''',
    );
    OpenMailAppResult result;

    try {
      result = await OpenMail.composeNewEmailInMailApp(
        nativePickerTitle: 'Select email app to contact support',
        emailContent: emailContent,
      );

      if (!result.didOpen && !result.canOpen) {
        showNoMailAppsDialog(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot send email.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int periodCount = _periods.length;
    final String restoreSummary = periodCount == 0
        ? 'All your data is ready to be restored.'
        : periodCount == 1
        ? 'All your data, including 1 logged period, is ready to be restored.'
        : 'All your data, including $periodCount logged periods, is ready to be restored.';
    final String restoreSummaryOverwrite = periodCount == 0
        ? 'All your data will be restored, replacing your existing data.'
        : periodCount == 1
        ? 'All your data, including 1 logged period, will be restored, replacing your existing data.'
        : 'All your data, including $periodCount logged periods, will be restored, replacing your existing data.';

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
                            child: Column(
                              children: [
                                Text(
                                  'There is an issue with your $kBackupFileName file.\nTry exporting the file on your old phone again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'If the problem persists ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        alignment: Alignment.centerLeft,
                                      ),
                                      onPressed: () => openEmail(),
                                      child: Text(
                                        'contact support',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          decorationColor: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Text('.'),
                                  ],
                                ),
                              ],
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
                    if (_error == null && _sharedFilePath != null)
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
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    '$restoreSummaryOverwrite\n'
                                    'Only proceed if you are sure you want to replace your existing data with the data in the backup file.',
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _restoreData,
                                  child: const Text('Restore from file'),
                                ),
                                const SizedBox(height: 50),
                                ElevatedButton(
                                  onPressed: () {
                                    context.go('/');
                                  },
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              'Want to keep your existing data?\n',
                                        ),
                                        TextSpan(
                                          text: 'Exit restore',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    restoreSummary,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _restoreData,
                                  child: const Text('Restore my data'),
                                ),
                                const SizedBox(height: 50),
                                ElevatedButton(
                                  onPressed: () {
                                    context.go('/onboarding');
                                  },
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              'Want to start fresh instead?\n',
                                        ),
                                        TextSpan(
                                          text: 'Start fresh',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
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
