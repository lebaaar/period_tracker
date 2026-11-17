import 'package:flutter/material.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/utils/reminder_actions.dart';
import 'package:period_tracker/widgets/grouped_section.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Settings? settings = context.watch<SettingsProvider>().settings;

    return LargeTitleScaffold(
      title: 'Reminders',
      slivers: [
        if (settings == null)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else
          SliverToBoxAdapter(
            child: GroupedSection(
              footer: 'You\'ll get a reminder this many days before your next period is expected, at the time you choose.',
              children: [
                GroupedRow(title: 'Days before', value: '${settings.notificationDaysBefore}', onTap: () => ReminderActions.editDaysBefore(context, settings)),
                GroupedRow(
                  title: 'Time',
                  value: DateTimeHelper.displayTime(settings.notificationTime),
                  onTap: () => ReminderActions.editTime(context, settings),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
