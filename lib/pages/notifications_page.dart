import 'package:flutter/material.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: settings == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildListTile(settings, 'notifications_days_before'),
                  _buildListTile(settings, 'notifications_time'),
                ],
              ),
      ),
    );
  }

  Widget _buildListTile(Settings settings, String tileType) {
    String title;
    String subtitle;
    Color subtitleColor = Theme.of(context).colorScheme.onSurface;

    switch (tileType) {
      case 'notifications_days_before':
        title = 'Notification Days Before';
        subtitle = settings.notificationDaysBefore.toString();
        break;
      case 'notifications_time':
        title = 'Notification Time';
        subtitle =
            '${settings.notificationTime.hour}:${settings.notificationTime.minute}';
        break;
      default:
        throw ArgumentError(
          '''Invalid tile type: $tileType. Should be one of the following:
          "notifications_days_before", "notifications_time".''',
        );
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
          case 'notifications_days_before':
            _showEditNotificationDaysBeforeDialog(settings, (newDays) {
              context.read<SettingsProvider>().updateSettings(
                notificationDaysBefore: int.parse(newDays),
                notificationTime: settings.notificationTime,
              );
            });
            break;
          // case 'notifications_time':
          //   _showEditCycleLengthDialog(settings, (newLength) {
          //     context.read<SettingsProvider>().updateSettings(
          //       cycleLength: int.parse(newLength),
          //       name: settings.name,
          //       periodLength: settings.periodLength,
          //       lastPeriodDate: user.lastPeriodDate,
          //     );
          //   });
          //   break;
          default:
            throw ArgumentError(
              '''Invalid tile type: $tileType. Should be one the following:
              "notifications_days_before", "notifications_time".''',
            );
        }
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  void _showEditNotificationDaysBeforeDialog(
    Settings settings,
    Function(String) onSave,
  ) {
    final TextEditingController controller = TextEditingController(
      text: settings.notificationDaysBefore.toString(),
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Notification Days Before'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter notification days before',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
