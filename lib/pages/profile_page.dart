import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:period_tracker/widgets/section_title.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _packageInfoFuture = PackageInfo.fromPlatform();
  late final TextEditingController _nameController;
  late final TextEditingController _cycleLengthController;
  late final TextEditingController _periodLengthController;

  int _versionTapCount = 0;
  bool _showVersionDetails = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayVersionPreference();

    _nameController = TextEditingController();
    _cycleLengthController = TextEditingController();
    _periodLengthController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayVersionPreference() async {
    final saved = await getDisplayVersionDetails();
    setState(() {
      _showVersionDetails = saved;
    });
  }

  void _onVersionTapped() async {
    if (_showVersionDetails) return;

    setState(() {
      _versionTapCount++;
    });

    if (_versionTapCount >= 9) {
      await setDisplayVersionDetailsValue(true);
      setState(() {
        _showVersionDetails = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<UserProvider>().user;
    final Settings? settings = context.watch<SettingsProvider>().settings;
    DateTime? nextPeriodDate = context.read<PeriodProvider>().getNextPeriodDate(
      settings?.predictionMode == 'dynamic',
      user?.cycleLength,
    );

    return SafeArea(
      child: user == null || settings == null
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(user, settings, nextPeriodDate),
    );
  }

  Widget _buildProfileContent(
    User user,
    Settings settings,
    DateTime? nextPeriodDate,
  ) {
    return ListView(
      children: [
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Do you really want to have a profile picture in a period tracking app?',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _getUserName(user),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 34),
        SectionTitle('Personal Information'),
        _buildListTile(user, settings, 'name'),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            if (settingsProvider.settings?.predictionMode == 'static') {
              return Column(
                children: [
                  _buildListTile(user, settings, 'cycle_length'),
                  _buildListTile(user, settings, 'period_length'),
                ],
              );
            }
            return SizedBox.shrink();
          },
        ),
        const Divider(),
        SectionTitle('Notifications'),
        FutureBuilder<bool>(
          future: getNotificationEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? true;
            return _buildSwitchTile(
              'Enable notifications',
              'Receive reminders for your next period',
              enabled,
              (value) async {
                setNotificationsValue(value);
                setState(() {});
                if (value) {
                  // reschedule notifications
                  NotificationService().scheduleNotificationsForNextPeriod(
                    nextPeriodDate,
                    settings.notificationDaysBefore,
                    settings.notificationTime,
                  );
                } else {
                  // cancel all notifications
                  NotificationService().cancelAllNotifications();
                }
              },
            );
          },
        ),
        FutureBuilder(
          future: getNotificationEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return enabled
                ? _buildListTile(user, settings, 'notifications')
                : SizedBox.shrink();
          },
        ),
        const Divider(),
        SectionTitle('App settings'),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return _buildSwitchTile(
              'Dynamic period prediction',
              settingsProvider.settings?.predictionMode == 'dynamic'
                  ? 'Next period date is based on your cycle history'
                  : 'Next period date is based on your cycle length you specify',
              settingsProvider.settings?.predictionMode == 'dynamic',
              (value) {
                // show conformation dialog
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Change Prediction Mode'),
                      content: Text(
                        value
                            ? 'Are you sure you want to switch to dynamic prediction? This will adjust your future period predictions based on your cycle history.'
                            : 'Are you sure you want to switch to static prediction? This will use the cycle length you specify in settings for future period predictions.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.tertiary,
                          ),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            String mode = value ? 'dynamic' : 'static';
                            settingsProvider.setPredictionMode(mode);

                            // nextPeriodDate changes here, reschedule notifications
                            nextPeriodDate = context
                                .read<PeriodProvider>()
                                .getNextPeriodDate(
                                  mode == 'dynamic',
                                  user.cycleLength,
                                );
                            NotificationService()
                                .scheduleNotificationsForNextPeriod(
                                  nextPeriodDate,
                                  settings.notificationDaysBefore,
                                  settings.notificationTime,
                                );
                            Navigator.of(context).pop();
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    );
                  },
                );
              },
            );
          },
        ),
        _buildListTile(user, settings, 'backup'),
        _buildListTile(user, settings, 'restore'),
        _buildListTile(user, settings, 'delete'),
        const SizedBox(height: 24),
        if (_showVersionDetails)
          Center(
            child: Text(
              'Made with ❤️ for Nina',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Center(
          child: GestureDetector(
            onTap: _onVersionTapped,
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: const CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox();
                }
                final packageInfo = snapshot.data!;
                return Text(
                  'Version ${packageInfo.version} ${packageInfo.buildNumber == '' ? '' : '(${packageInfo.buildNumber})'}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildListTile(User user, Settings? settings, String tileType) {
    String title;
    String subtitle;

    switch (tileType) {
      case 'name':
        title = 'Name';
        subtitle = _getUserName(user);
        break;
      case 'cycle_length':
        title = 'Cycle Length';
        subtitle = user.cycleLength.toString();
        break;
      case 'period_length':
        title = 'Period Length';
        subtitle = user.periodLength.toString();
        break;
      case 'notifications':
        title = 'Notifications';
        subtitle = 'Manage your notification settings';
        break;
      case 'backup':
        title = 'Backup Data';
        subtitle =
            'Backup your data (for transfer or restore on another device)';
        break;
      case 'restore':
        title = 'Restore Data';
        subtitle = 'Restore data from a backup file';
        break;
      case 'delete':
        title = 'Delete Account';
        subtitle = 'Permanently delete your account and all data';
        break;
      default:
        throw ArgumentError('''Invalid tile type: $tileType. Should be
          "name", "cycle_length", "period_length", "notifications", "backup",
          "restore" or "delete".''');
    }

    return ListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded),
      onTap: () {
        switch (tileType) {
          case 'name':
            _showEditNameDialog(user, (newName) {
              context.read<UserProvider>().updateUser(
                name: newName,
                cycleLength: user.cycleLength,
                periodLength: user.periodLength,
                lastPeriodDate: user.lastPeriodDate,
              );
            });
            break;
          case 'cycle_length':
            _showEditCycleLengthDialog(user, (newLength) {
              context.read<UserProvider>().updateUser(
                cycleLength: int.parse(newLength),
                name: user.name,
                periodLength: user.periodLength,
                lastPeriodDate: user.lastPeriodDate,
              );

              // update nextPeriodDate if prediction mode is static
              DateTime? nextPeriodDate = context
                  .read<PeriodProvider>()
                  .getNextPeriodDate(
                    settings?.predictionMode == 'dynamic',
                    int.parse(newLength),
                  );
              NotificationService().scheduleNotificationsForNextPeriod(
                nextPeriodDate,
                settings!.notificationDaysBefore,
                settings.notificationTime,
              );
            });
            break;
          case 'period_length':
            _showEditPeriodLengthDialog(user, (newLength) {
              context.read<UserProvider>().updateUser(
                periodLength: int.parse(newLength),
                name: user.name,
                cycleLength: user.cycleLength,
                lastPeriodDate: user.lastPeriodDate,
              );

              // periodLength change does not affect nextPeriodDate, no notification reschedule needed
              // periodLength is only used for auto-logging period end date
              // possible TODO: if user is currently on period, update the end date based on new period length
            });
            break;
          case 'notifications':
            context.go('/notifications');
            break;
          case 'backup':
            _showBackupDialog();
            break;
          case 'restore':
            _showRestoreDialog();
            break;
          case 'delete':
            _showDeleteAccountDialog();
            break;
          default:
            throw ArgumentError(
              '''Invalid tile type: $tileType. Should be one the following:
              "name", "cycle_length", "period_length",  "notifications",
              "backup", "restore" or "delete".''',
            );
        }
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  // Dialogs
  void _showEditNameDialog(User user, Function(String) onSave) {
    _nameController.text = user.name ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(_nameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  void _showEditCycleLengthDialog(User user, Function(String) onSave) {
    _cycleLengthController.text = user.cycleLength.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit cycle length'),
          content: TextField(
            controller: _cycleLengthController,
            decoration: InputDecoration(
              hintText: 'Average cycle length',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!PeriodService.validateCycleLength(
                  int.tryParse(_cycleLengthController.text),
                )) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid cycle length.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                onSave(_cycleLengthController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  void _showEditPeriodLengthDialog(User user, Function(String) onSave) {
    _periodLengthController.text = user.periodLength.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit period length'),
          content: TextField(
            controller: _periodLengthController,
            decoration: InputDecoration(
              hintText: 'Average period length',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!PeriodService.validatePeriodLength(
                  int.tryParse(_periodLengthController.text),
                )) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid period length.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                onSave(_periodLengthController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Backup Data'),
          content: const Text('This feature is not implemented yet :('),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  void _showRestoreDialog() {
    // file picker...
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Data'),
          content: const Text('This feature is not implemented yet :('),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ApplicationDataService().clearAppData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/onboarding');
                }
              },
              child: const Text('Delete'),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      },
    );
  }

  // Helpers
  String _getUserName(User user) {
    return user.name?.isNotEmpty == true ? user.name! : kMysteriousUserName;
  }
}
