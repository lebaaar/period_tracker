import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/theme_provider.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/utils/reminder_actions.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/delete_account_sheet.dart';
import 'package:period_tracker/widgets/grouped_section.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/segmented_control.dart';
import 'package:period_tracker/widgets/stepper_field.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppUpdateInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    InAppUpdate.checkForUpdate()
        .then((info) {
          if (mounted) setState(() => _updateInfo = info);
        })
        .catchError((e) {});
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<UserProvider>().user;
    final Settings? settings = context.watch<SettingsProvider>().settings;

    return LargeTitleScaffold(
      title: 'Settings',
      showBack: false,
      slivers: [
        if (user == null || settings == null)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else
          SliverList.list(children: _content(user, settings)),
      ],
    );
  }

  List<Widget> _content(User user, Settings settings) {
    final UnlocksProvider unlocks = context.watch<UnlocksProvider>();
    final bool dynamicMode = settings.predictionMode == 'dynamic';
    final bool notificationsOn = settings.notificationsEnabled;

    return [
      _ProfileHeader(
        name: _getUserName(user),
        onEdit: () => _editName(user),
        onAvatarTap: () => _snack('Do you really want to have a profile picture in a period tracking app?'),
      ),
      GroupedSection(
        header: 'Cycle',
        footer: dynamicMode
            ? 'Predictions follow the average of your recent cycles. Turn this off to set your cycle length yourself.'
            : 'Predictions use the cycle and period length you set here.',
        children: [
          GroupedRow(
            title: 'Smart predictions',
            subtitle: dynamicMode ? 'Based on your history' : 'Based on your settings',
            onTap: () => _confirmPredictionMode(user, settings, !dynamicMode),
            trailing: Switch(value: dynamicMode, onChanged: (v) => _confirmPredictionMode(user, settings, v)),
          ),
          GroupedRow(title: 'Period length', value: '${user.periodLength} days', enabled: !dynamicMode, onTap: () => _editPeriodLength(user)),
          GroupedRow(title: 'Cycle length', value: '${user.cycleLength} days', enabled: !dynamicMode, onTap: () => _editCycleLength(user, settings)),
          if (unlocks.orderBoyfriend)
            GroupedRow(title: 'Order boyfriend message', subtitle: 'Title added to every message', onTap: () => _editPartnerHeading(user)),
        ],
      ),
      GroupedSection(
        header: 'Reminders',
        children: [
          GroupedRow(
            title: 'Period reminders',
            subtitle: 'Get notified before your period',
            onTap: () => _toggleNotifications(user, settings, !notificationsOn),
            trailing: Switch(value: notificationsOn, onChanged: (v) => _toggleNotifications(user, settings, v)),
          ),
          if (notificationsOn) ...[
            GroupedRow(title: 'Days before', value: '${settings.notificationDaysBefore}', onTap: () => ReminderActions.editDaysBefore(context, settings)),
            GroupedRow(title: 'Time', value: DateTimeHelper.displayTime(settings.notificationTime), onTap: () => ReminderActions.editTime(context, settings)),
          ],
        ],
      ),
      GroupedSection(
        header: 'Appearance',
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedControl<ThemeMode>(
              onCard: true,
              options: const [
                SegmentOption(value: ThemeMode.system, label: 'Auto', icon: Icons.brightness_auto_rounded),
                SegmentOption(value: ThemeMode.light, label: 'Light', icon: Icons.light_mode_rounded),
                SegmentOption(value: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_rounded),
              ],
              selected: context.watch<ThemeProvider>().mode,
              onChanged: (m) => context.read<ThemeProvider>().setMode(m),
            ),
          ),
        ],
      ),
      GroupedSection(
        header: 'Your data',
        footer: 'Everything stays on this device. Use a backup file to move to a new phone.',
        children: [
          GroupedRow(title: 'Transfer data', subtitle: 'Save a backup file for another device', icon: Icons.ios_share_rounded, onTap: _showTransfer),
          GroupedRow(
            title: 'Delete account',
            subtitle: 'Permanently erase all data',
            icon: Icons.delete_outline_rounded,
            destructive: true,
            onTap: _confirmDelete,
          ),
        ],
      ),
      GroupedSection(
        header: 'About',
        children: [
          GroupedRow(title: 'App info', subtitle: 'Version, contact & support', icon: Icons.info_outline_rounded, onTap: () => context.push('/about')),
          if (unlocks.animalGenerator) GroupedRow(title: 'Doggy generator', icon: Icons.pets_rounded, onTap: () => context.push('/animal')),
        ],
      ),
    ];
  }

  Future<void> _editName(User user) async {
    final String? name = await showTextSheet(
      context: context,
      title: 'Your name',
      initial: user.name ?? '',
      hint: 'Name',
      capitalization: TextCapitalization.words,
    );
    if (name == null || !mounted) return;
    context.read<UserProvider>().updateUser(name: name.trim(), cycleLength: user.cycleLength, periodLength: user.periodLength);
  }

  Future<void> _editPeriodLength(User user) async {
    final int? value = await showNumberSheet(
      context: context,
      title: 'Period length',
      message: 'How many days your period usually lasts.',
      initial: user.periodLength,
      min: kMinPeriodLength,
      max: kMaxPeriodLength,
    );
    if (value == null || !mounted) return;
    // periodLength doesn't affect the next period date, so no reschedule is needed
    context.read<UserProvider>().updateUser(periodLength: value, name: user.name, cycleLength: user.cycleLength);
  }

  Future<void> _editCycleLength(User user, Settings settings) async {
    final int? value = await showNumberSheet(
      context: context,
      title: 'Cycle length',
      message: 'Days from the first day of one period to the first day of the next.',
      initial: user.cycleLength,
      min: kMinCycleLength,
      max: kMaxCycleLength,
    );
    if (value == null || !mounted) return;
    context.read<UserProvider>().updateUser(cycleLength: value, name: user.name, periodLength: user.periodLength);

    final DateTime? next = context.read<PeriodProvider>().getNextPeriodDate(settings.predictionMode == 'dynamic', value);
    await NotificationService().scheduleNotificationsForNextPeriod(next, settings.notificationDaysBefore, settings.notificationTime);
  }

  Future<void> _editPartnerHeading(User user) async {
    final String? text = await showTextSheet(
      context: context,
      title: 'Order boyfriend message',
      message: 'This text is added at the start of every message you send from Today.',
      initial: user.partnerMessageHeading ?? '',
      hint: 'Title message',
      maxLines: 4,
    );
    if (text == null || !mounted) return;
    context.read<UserProvider>().updateUser(name: user.name, cycleLength: user.cycleLength, periodLength: user.periodLength, partnerMessageHeading: text);
  }

  Future<void> _toggleNotifications(User user, Settings settings, bool value) async {
    final SettingsProvider provider = context.read<SettingsProvider>();
    final DateTime? next = context.read<PeriodProvider>().getNextPeriodDate(settings.predictionMode == 'dynamic', user.cycleLength);
    await provider.setNotificationEnabled(value);
    if (value) {
      await NotificationService().scheduleNotificationsForNextPeriod(next, settings.notificationDaysBefore, settings.notificationTime);
    } else {
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> _confirmPredictionMode(User user, Settings settings, bool dynamic) async {
    final SettingsProvider provider = context.read<SettingsProvider>();
    final PeriodProvider periods = context.read<PeriodProvider>();
    final bool ok = await showConfirm(
      context: context,
      title: dynamic ? 'Use smart predictions?' : 'Use fixed cycle length?',
      message: dynamic ? 'Future predictions will adapt to your cycle history.' : 'Future predictions will use the cycle length you set in settings.',
      confirmLabel: 'Switch',
    );
    if (!ok) return;
    final String mode = dynamic ? 'dynamic' : 'static';
    provider.setPredictionMode(mode);
    // nextPeriodDate changes here, reschedule notifications
    final DateTime? next = periods.getNextPeriodDate(dynamic, user.cycleLength);
    await NotificationService().scheduleNotificationsForNextPeriod(next, settings.notificationDaysBefore, settings.notificationTime);
  }

  Future<void> _exportData() async {
    try {
      final String backupContent = await ApplicationDataService().createBackupFileContent();
      final XFile backupFile = await ApplicationDataService().exportBackupToFile(backupContent);

      final bool emailSent = await ApplicationDataService().shareBackup(backupFile);
      if (!mounted) return;
      _snack(emailSent ? 'Backup file sent successfully' : 'Warning: backup file not sent');
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to export backup :(');
    }
  }

  Future<void> _showTransfer() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      await _showUpdateNeeded();
      return;
    }

    bool send = false;
    await showAppSheet<void>(
      context: context,
      title: 'Transfer data',
      actionLabel: 'Send backup file',
      onAction: () => send = true,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All your data is saved into a $kBackupFileName file. Send it to yourself (for example by email) and open it with Period Tracker on your new device to restore everything.',
            style: sheetContext.text.bodyMedium?.copyWith(color: sheetContext.colors.labelSecondary),
          ),
          const SizedBox(height: 8),
          Pressable(
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.push('/help?initialPage=transfer');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Need help?', style: sheetContext.text.titleSmall?.copyWith(decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
    if (send) await _exportData();
  }

  Future<void> _showUpdateNeeded() async {
    final bool go = await showConfirm(
      context: context,
      title: 'Update needed',
      message: 'Please update the app before transferring data. Both devices need to be on the same version.',
      confirmLabel: 'Go to Play Store',
      cancelLabel: 'Close',
    );
    if (!go || !Platform.isAndroid) return;
    final Uri uri = Uri.parse(kGooglePlayStoreUrl);
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

  Future<void> _confirmDelete() async {
    final bool ok = await showDeleteAccountSheet(context);
    if (!ok || !mounted) return;

    // delete account data, then remove scheduled notifications
    final UnlocksProvider unlocks = context.read<UnlocksProvider>();
    await ApplicationDataService().clearAppData();
    await NotificationService().cancelAllNotifications();
    await unlocks.reload();

    if (mounted) {
      _snack('Account deleted successfully');
      context.go('/onboarding');
    }
  }

  String _getUserName(User user) => user.name?.isNotEmpty == true ? user.name! : kMysteriousUserName;
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final VoidCallback onEdit;
  final VoidCallback onAvatarTap;
  const _ProfileHeader({required this.name, required this.onEdit, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final String initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Pressable(
        onTap: onEdit,
        pressedScale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child: Text(initial, style: context.text.titleLarge?.copyWith(color: c.onAccent)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Edit name', style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.labelTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
