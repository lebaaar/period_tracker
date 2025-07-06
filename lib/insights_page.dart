import 'package:flutter/material.dart';

class InsightsPage extends StatefulWidget {
  final bool isSelected;
  const InsightsPage({super.key, required this.isSelected});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  Widget build(BuildContext context) {
    return widget.isSelected
        ? Center(child: Text('Insights', style: TextStyle(fontSize: 24)))
        : const SizedBox.shrink();
  }
}
