import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/primary_button.dart';

class OnboardingRestoreDataPage extends StatelessWidget {
  const OnboardingRestoreDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LargeTitleScaffold(
      title: 'Restore data',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'To restore your data you need the $kBackupFileName file on this device. Find it in your Files app and open it with Period Tracker.',
              style: context.text.bodyLarge?.copyWith(color: c.labelSecondary),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: PrimaryButton(label: 'How do I do that?', style: AppButtonStyle.secondary, onPressed: () => context.push('/help?initialPage=restore')),
          ),
        ),
      ],
    );
  }
}
