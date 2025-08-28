import 'package:flutter/material.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/utils/string_helper.dart';
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
          icon: const Icon(Icons.arrow_back_rounded),
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
        title = 'Notification days before period';
        subtitle = settings.notificationDaysBefore.toString();
        break;
      case 'notifications_time':
        title = 'Notification Time';
        subtitle = StringHelper.displayTime(settings.notificationTime);
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
        Icons.chevron_right_rounded,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 50),
      ),
      onTap: () {
        switch (tileType) {
          case 'notifications_days_before':
            _showEditNotificationDaysBeforeDialog(settings, (newDays) {
              // Validate input
              if (newDays.isEmpty || int.tryParse(newDays) == null) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              // Check max days before
              if (int.parse(newDays) > kMaxNotificationsDaysBefore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notifications can only be sent up to $kMaxNotificationsDaysBefore days before the period starts.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              context.read<SettingsProvider>().updateSettings(
                notificationDaysBefore: int.parse(newDays),
              );
            });
            break;
          case 'notifications_time':
            _showEditCycleLengthDialog(settings, (newLength) {
              context.read<SettingsProvider>().updateSettings(
                notificationTime: TimeOfDay(
                  hour: int.parse(newLength.split(':')[0]),
                  minute: int.parse(newLength.split(':')[1]),
                ),
              );
            });
            break;
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
          title: const Text('Notification days before period'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter notification days before',
            ),
            keyboardType: TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
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

  void _showEditCycleLengthDialog(Settings settings, Function(String) onSave) {
    showTimePicker(
      context: context,
      initialTime: settings.notificationTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    ).then((TimeOfDay? time) {
      if (time != null) {
        onSave('${time.hour}:${time.minute}');
      }
    });
  }
}
