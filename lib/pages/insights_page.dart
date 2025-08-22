import 'package:flutter/material.dart';
import 'package:period_tracker/providers/period_provider.dart';
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
    List<Period> periods = context.watch<PeriodProvider>().periods;

    return SafeArea(
      child: periods.isEmpty
          ? const Center(child: Text('No periods logged.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: periods.length,
              itemBuilder: (context, index) {
                final period = periods[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Start: 	${period.startDate.toLocal().toIso8601String().split('T').first}',
                    ),
                    subtitle: Text(
                      period.endDate != null
                          ? 'End:   ${period.endDate!.toLocal().toIso8601String().split('T').first}'
                          : 'Ongoing',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
