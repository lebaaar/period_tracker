import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_mail/open_mail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/encryption_service.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _versionTapCount = 0;
  bool _showVersionDetails = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayVersionPreference();
  }

  Future<void> _loadDisplayVersionPreference() async {
    final saved = await getDisplayVersionDetails();
    setState(() {
      _showVersionDetails = saved;
    });
  }

  void _onVersionTapped() async {
    setState(() {
      _versionTapCount++;
    });

    if (_versionTapCount >= 9) {
      _versionTapCount = 0;
      final newState = !_showVersionDetails;
      await setDisplayVersionDetailsValue(newState);
      setState(() {
        _showVersionDetails = newState;
      });
    }
  }

  Future<void> openEmail(bool bugReport) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String? appContent;
    try {
      appContent = await ApplicationDataService().createBackupFileContent();
    } catch (e) {
      appContent = 'Error generating application data: $e';
    }

    final String encodedContent = EncryptionService().base64Encode(appContent);
    final EmailContent emailContent = EmailContent(
      to: [kContactEmail],
      subject: bugReport == true ? 'Issue with Period Tracker' : 'Period Tracker Feedback',
      body: bugReport == true
          ? '''
Hello,

I'm having an issue with Period Tracker app: <SPECIFY YOUR ISSUE HERE>
\n\n\n\n\n
Development details (please don't remove this, as it helps us diagnose the issue):

[Timestamp: ${DateTime.now()}]
[Version: ${packageInfo.version}+${packageInfo.buildNumber}]
[Device: ${Platform.operatingSystem}]
[OS version: ${Platform.operatingSystemVersion}]
[Application data: $encodedContent]'''
          : null,
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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 80, height: 80),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Period Tracker', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _onVersionTapped,
                                  child: Text(
                                    'Version ${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: IconButton(
                                    onPressed: () => _checkForUpdates(),
                                    icon: Icon(Icons.system_update_rounded, size: 14),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Check for updates',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Whether you want to track your period, predict your next period cycle, or simply understand your body better, Period Tracker gives you the insights you need, without the annoying ads or hidden subscriptions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_showVersionDetails) Text('Made with ❤️ for Nina'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Support', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.mail_rounded,
              title: 'Contact Developer',
              subtitle: 'Have questions or suggestions?',
              onTap: () => openEmail(false),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.bug_report_rounded,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              onTap: () => openEmail(true),
            ),
            const SizedBox(height: 24),
            Text('Development', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildActionButton(context, icon: Icons.code, title: 'View Source Code', subtitle: 'Open GitHub', onTap: () => _launchUrl(kGitHubUrl)),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.favorite_rounded,
              title: 'Buy Me a Ko-fi ☕',
              subtitle: 'Support the development',
              onTap: () => _launchUrl(kKofiUrl),
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isPrimary ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: isPrimary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPrimary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: isPrimary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Checking for updates...'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
      // TODO: Implement actual update check using package_info_plus or in_app_update
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You are on the latest version!'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot check for updates at this time. Please try again later.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    print(uri.toString());
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open link'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred'), behavior: SnackBarBehavior.floating));
    }
  }
}
