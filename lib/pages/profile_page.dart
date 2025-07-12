import 'package:flutter/material.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _name;
  int? cycleLength;
  int? periodLength;
  DateTime? lastPeriodDate;

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    _name = user?.name;
    cycleLength = user?.cycleLength;
    periodLength = user?.periodLength;
    lastPeriodDate = user?.lastPeriodDate;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Name: ${_name ?? 'Not set'}'),
            Text('Cycle Length: ${cycleLength ?? 'Not set'} days'),
            Text('Period Length: ${periodLength ?? 'Not set'} days'),
            Text('Last Period Date: ${lastPeriodDate?.toLocal() ?? 'Not set'}'),
          ],
        ),
      ),
    );
  }
}
