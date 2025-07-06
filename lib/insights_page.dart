import 'package:flutter/material.dart';
import 'models/period.dart';

class InsightsPage extends StatefulWidget {
  final bool isSelected;
  const InsightsPage({super.key, required this.isSelected});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  // TODO: fetch from database
  final List<Period> periods = [
    Period(startDate: DateTime(2024, 6, 1), endDate: DateTime(2024, 6, 6)),
    Period(startDate: DateTime(2024, 6, 28), endDate: DateTime(2024, 7, 3)),
    Period(startDate: DateTime(2024, 7, 25), endDate: DateTime(2024, 7, 30)),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Insights page'));
  }
}
