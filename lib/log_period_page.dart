import 'package:flutter/material.dart';

class LogPeriodPage extends StatelessWidget {
  const LogPeriodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Period')),
      body: const Center(child: Text('Add or edit your period details here.')),
    );
  }
}
