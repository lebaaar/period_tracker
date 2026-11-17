import 'package:flutter/material.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/segmented_control.dart';

/// Help for restoring and transferring data. [initialTab] is 'restore' or 'transfer'.
class RestoreHelpPage extends StatefulWidget {
  final String initialTab;

  const RestoreHelpPage({super.key, this.initialTab = 'restore'});

  @override
  State<RestoreHelpPage> createState() => _RestoreHelpPageState();
}

class _RestoreHelpPageState extends State<RestoreHelpPage> {
  late bool _transfer = widget.initialTab == 'transfer';

  void _showEnlargedImage(BuildContext context, String imagePath) {
    showAppSheet<void>(
      context: context,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> steps = _transfer ? _transferSteps(context) : _restoreSteps(context);
    return LargeTitleScaffold(
      title: 'Help',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SegmentedControl<bool>(
              options: const [
                SegmentOption(value: false, label: 'Restore data'),
                SegmentOption(value: true, label: 'Transfer data'),
              ],
              selected: _transfer,
              onChanged: (v) => setState(() => _transfer = v),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(key: ValueKey(_transfer), crossAxisAlignment: CrossAxisAlignment.start, children: steps),
            ),
          ),
        ),
      ],
    );
  }

  Widget _intro(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Text(text, style: context.text.bodyLarge?.copyWith(color: context.colors.labelSecondary)),
  );

  Widget _note(BuildContext context, String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: context.colors.card, borderRadius: BorderRadius.circular(16)),
    child: Text(text, style: context.text.bodyMedium),
  );

  Widget _step(BuildContext context, int number, String text, {String? image}) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                child: Text('$number', style: context.text.titleSmall?.copyWith(color: c.onAccent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(text, style: context.text.bodyLarge),
                ),
              ),
            ],
          ),
          if (image != null) ...[
            const SizedBox(height: 14),
            Pressable(
              onTap: () => _showEnlargedImage(context, image),
              pressedScale: 0.99,
              child: Center(
                child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(image, height: 320)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _restoreSteps(BuildContext context) => [
    _intro(context, 'To restore your data you need the $kBackupFileName file on your new device. Here is how.'),
    _note(
      context,
      'Before you start: install Period Tracker on your new device and get the $kBackupFileName file onto it. If you don\'t have the file yet, see "Transfer data".',
    ),
    _step(
      context,
      1,
      'On your new device, open the email you sent to yourself and download the $kBackupFileName file.',
      image: 'assets/images/tutorials/restore-gmail.png',
    ),
    _step(context, 2, 'Open the Files app. It may look different depending on your device.', image: 'assets/images/tutorials/restore-files-app.png'),
    _step(
      context,
      3,
      'Find the $kBackupFileName file. By default it is in the Downloads folder.',
      image: 'assets/images/tutorials/restore-files-downloads.png',
    ),
    _step(context, 4, 'Long press the file, tap the 3 dots and choose "Open with".', image: 'assets/images/tutorials/restore-open-with.png'),
    _step(context, 5, 'Choose Period Tracker from the list of apps.', image: 'assets/images/tutorials/restore-open.png'),
    _step(context, 6, 'Tap "Restore my data" to confirm.', image: 'assets/images/tutorials/restore-preview.png'),
    _note(context, 'If this device already has an account, restoring replaces all existing data with the contents of the backup file.'),
    _step(context, 7, 'That\'s it. Your data is restored.', image: 'assets/images/tutorials/restore-success.png'),
  ];

  List<Widget> _transferSteps(BuildContext context) => [
    _intro(context, 'To move to another device you carry a backup file from the old one to the new one. Here is how.'),
    _step(
      context,
      1,
      'On your old device, open Settings and tap "Transfer data" under "Your data".',
      image: 'assets/images/tutorials/transfer-profile-page.png',
    ),
    _step(
      context,
      2,
      'Tap "Send backup file". Sharing options open with the $kBackupFileName file attached.',
      image: 'assets/images/tutorials/transfer-dialog.png',
    ),
    _step(
      context,
      3,
      'Choose how to share it, for example by email. You need to be able to open it on your new device.',
      image: 'assets/images/tutorials/transfer-share.png',
    ),
    _step(
      context,
      4,
      'If you chose email, your email app opens with the file attached. Send it to yourself.',
      image: 'assets/images/tutorials/transfer-gmail.png',
    ),
    _note(context, 'Next, follow the steps under "Restore data" on your new device.'),
  ];
}
