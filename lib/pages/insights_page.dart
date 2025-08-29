import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/widgets/section_title.dart';
import 'package:provider/provider.dart';
import '../models/period_model.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  Widget build(BuildContext context) {
    final periodProvider = Provider.of<PeriodProvider>(context);
    List<Period> periods = context.watch<PeriodProvider>().periods;
    // TODO: support sorting from UI
    periods.sort(
      (a, b) => b.startDate.compareTo(a.startDate),
    ); // default soring by date descending

    return SafeArea(
      child: periods.isEmpty
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No periods logged',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When you log periods, insights will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: () {
                      context.go(
                        '/log?isEditing=false&focusedDay=${Uri.encodeComponent(DateTime.now().toIso8601String())}',
                      );
                    },
                    child: Text('Log Period'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 130,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _statCard(
                          title: "Average Cycle Length",
                          value:
                              periodProvider
                                  .getAverageCycleLength()
                                  ?.toStringAsFixed(1) ??
                              'N/A days',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          title: "Average Period Length",
                          value:
                              periodProvider
                                  .getAveragePeriodLength()
                                  ?.toStringAsFixed(1) ??
                              'N/A days',
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  child: SectionTitle('Period History'),
                  alignment: Alignment.centerLeft,
                ),
                Expanded(
                  child: ListView(
                    children: periods.map((period) {
                      return ListTile(
                        leading: Icon(
                          Icons.calendar_month_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          'Start: ${DateTimeHelper.displayDate(period.startDate)}',
                        ),
                        subtitle: Text(
                          period.endDate != null
                              ? 'End: ${DateTimeHelper.displayDate(period.endDate!)}'
                              : 'Ongoing',
                        ),
                        trailing: Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          context.go(
                            '/log?isEditing=true&periodId=${period.id}&focusedDay=${Uri.encodeComponent(period.startDate.toIso8601String())}',
                          );
                          return;
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard({required String title, required String value}) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
