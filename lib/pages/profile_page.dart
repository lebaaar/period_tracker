import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cycleLengthController = TextEditingController();
  final TextEditingController _periodLengthController = TextEditingController();
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = _getPackageInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    return SafeArea(
      child: user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(user),
    );
  }

  Widget _buildProfileContent(User user) {
    return ListView(
      children: [
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Do you really want to have a profile picture in a period tracking app?',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[800],
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _getUserName(user),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 34),
        _buildSectionTitle('Personal Information'),
        _buildListTile(user, 'name'),
        _buildListTile(user, 'cycle_length'),
        _buildListTile(user, 'period_length'),
        const SizedBox(height: 24),
        _buildSectionTitle('Notifications'),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return _buildSwitchTile(
              'Enable notifications',
              'Receive reminders for your next period',
              settingsProvider.notificationEnabled,
              (value) {
                settingsProvider.toggleNotificationEnabled(value);
              },
            );
          },
        ),
        Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return settingsProvider.notificationEnabled
                ? _buildListTile(user, 'notifications')
                : SizedBox.shrink();
          },
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('App settings'),
        _buildSwitchTile(
          'Dynamic period prediction',
          'Predict the next period based on your cycle history',
          true,
          (value) {
            // context.read<UserProvider>().toggleDarkMode(value);
          },
        ),
        _buildListTile(user, 'backup'),
        _buildListTile(user, 'restore'),
        _buildListTile(user, 'delete'),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Made with ❤️ for Nina',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
            ),
          ),
        ),
        Center(
          child: FutureBuilder<PackageInfo>(
            future: _getPackageInfo(),
            builder: (context, snapshot) {
              // simulate loading state, wait 5sec
              // sleep(const Duration(seconds: 5));

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: const CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                // Cannot retrieve package info
                // print('Error retrieving package info: ${snapshot.error}');
                return SizedBox();
              }
              final packageInfo = snapshot.data!;
              return Text(
                'Version ${packageInfo.version} (${packageInfo.buildNumber})',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Widgets
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
        ),
      ),
    );
  }

  Widget _buildListTile(User user, String tileType) {
    String title;
    String subtitle;
    Color subtitleColor = Theme.of(context).colorScheme.onSurface;

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
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: subtitleColor)),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 50),
      ),
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
            });
            break;
          case 'notifications':
            // TODO: notifications settings page
            Navigator.pushNamed(context, '/notifications');
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
    String subittle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: Text(
        subittle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 50),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      inactiveTrackColor: Colors.grey[800],
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
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(200),
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
          backgroundColor: Color(0xFF121212),
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
            decoration: const InputDecoration(hintText: 'Average cycle length'),
            keyboardType: TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(200),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!PeriodService.validateCycleLength(
                  int.tryParse(_cycleLengthController.text),
                )) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid cycle length.'),
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
          backgroundColor: Color(0xFF121212),
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
            decoration: const InputDecoration(
              hintText: 'Average period length',
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
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(200),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!PeriodService.validatePeriodLength(
                  int.tryParse(_periodLengthController.text),
                )) {
                  Navigator.of(context).pop();
                  // TODO: prevent queue of snack bars
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid period length.'),
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
          backgroundColor: Color(0xFF121212),
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
          content: const Text('This feature is not implemented yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
          backgroundColor: Color(0xFF121212),
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
          content: const Text('This feature is not implemented yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
          backgroundColor: Color(0xFF121212),
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
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha(200),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ApplicationDataService().clearAppData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App data cleared!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  context.go('/onboarding');
                }
              },
              child: const Text('Delete'),
            ),
          ],
          backgroundColor: Color(0xFF121212),
        );
      },
    );
  }

  // Helpers
  String _getUserName(User user) {
    return user.name?.isNotEmpty == true ? user.name! : 'Mysterious User';
  }

  Future<PackageInfo> _getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
}
