import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/email_type.dart';
import 'package:period_tracker/exceptions/email_exception.dart';
import 'package:period_tracker/services/email_service.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/grouped_section.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  AppUpdateInfo? _updateInfo;
  int _versionTapCount = 0;
  bool _isCheckingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  void _onVersionTapped() {
    _versionTapCount++;
    if (_versionTapCount >= 9) {
      _versionTapCount = 0;
      final UnlocksProvider unlocks = context.read<UnlocksProvider>();
      unlocks.setVersionDetails(!unlocks.versionDetails);
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    try {
      // simulate loading
      await Future.delayed(const Duration(seconds: 1));
      final info = await InAppUpdate.checkForUpdate();

      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _isCheckingForUpdate = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingForUpdate = false;
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> openEmail(EmailType emailType) async {
    try {
      await EmailService.openEmail(emailType, null);
    } on EmailException catch (e) {
      if (!mounted) return;
      switch (e.errorCode) {
        case kNoEmailAppErrorCode:
          showInfo(context: context, title: 'No email app found', message: 'Install an email app to contact support.');
          return;
        case kUnknownErrorCode:
          _snack('An error occurred while trying to open email app');
          return;
      }
    } catch (_) {
      if (!mounted) return;
      _snack('An error occurred while trying to open email app');
    }
  }

  Future<void> _openPlayStore() async {
    if (Platform.isAndroid) {
      _launchUrl(kGooglePlayStoreUrl);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _snack('Cannot open link');
      }
    } catch (e) {
      if (mounted) _snack('An error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool showVersionDetails = context.watch<UnlocksProvider>().versionDetails;
    final bool updateAvailable = _updateInfo?.updateAvailability == UpdateAvailability.updateAvailable;

    return LargeTitleScaffold(
      title: 'About',
      largeTitle: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.asset('assets/images/logo.png', width: 88, height: 88)),
                const SizedBox(height: 16),
                Text('Period Tracker', style: context.text.headlineSmall),
                const SizedBox(height: 6),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 20);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onVersionTapped,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                              style: context.text.bodyMedium?.copyWith(color: c.labelSecondary),
                            ),
                          ),
                        ),
                        if (_isCheckingForUpdate) ...[
                          const SizedBox(width: 10),
                          const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        ] else if (updateAvailable) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _openPlayStore,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(99)),
                              child: Text(
                                'Update available',
                                style: context.text.labelMedium?.copyWith(color: c.onAccent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Track your period and predict the next one, without ads or subscriptions. Your data stays on your device.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: c.labelSecondary),
                ),
                if (showVersionDetails) ...[
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Made with '),
                        TextSpan(text: '\u2764\uFE0F', style: _emojiStyle),
                        const TextSpan(text: ' for Nina'),
                      ],
                    ),
                    style: context.text.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: GroupedSection(
            header: 'Support',
            children: [
              GroupedRow(
                icon: Icons.mail_outline_rounded,
                title: 'Contact developer',
                subtitle: 'Questions or suggestions',
                onTap: () => openEmail(EmailType.feedback),
              ),
              GroupedRow(icon: Icons.bug_report_outlined, title: 'Report a bug', subtitle: 'Help improve the app', onTap: () => openEmail(EmailType.bugReport)),
              GroupedRow(
                icon: Icons.star_outline_rounded,
                title: 'Rate Period Tracker',
                subtitle: 'Leave a review on Google Play',
                onTap: () => _launchUrl(kGooglePlayStoreUrl),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: GroupedSection(
            header: 'Development',
            children: [
              GroupedRow(icon: Icons.code_rounded, title: 'Source code', subtitle: 'Open on GitHub', onTap: () => _launchUrl(kGitHubUrl)),
              GroupedRow(
                icon: Icons.coffee_rounded,
                iconColor: context.colors.accent,
                title: 'Buy me a Ko-fi',
                subtitle: 'Support the development',
                onTap: () => _launchUrl(kKofiUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Inter has its own monochrome heart; name the emoji font so the colour one is used.
final TextStyle _emojiStyle = TextStyle(
  fontFamily: (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) ? 'Apple Color Emoji' : 'Noto Color Emoji',
  fontFamilyFallback: const ['Noto Color Emoji', 'Apple Color Emoji'],
);
