import 'package:flutter/material.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:provider/provider.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Period> periods = context.watch<PeriodProvider>().periods;

    return SafeArea(
      child: Center(
        child: Column(children: [for (Period period in periods) Text('Period(startDate: ${period.startDate}, endDate: ${period.endDate})\n')]),
      ),
    );
  }
}
