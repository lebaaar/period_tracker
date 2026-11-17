import 'package:flutter/material.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/primary_button.dart';

/// Two-step delete confirmation; true only after both steps.
Future<bool> showDeleteAccountSheet(BuildContext context) async {
  final bool? confirmed = await showAppSheet<bool>(context: context, builder: (_) => const DeleteAccountFlow());
  return confirmed ?? false;
}

class DeleteAccountFlow extends StatefulWidget {
  const DeleteAccountFlow({super.key});

  @override
  State<DeleteAccountFlow> createState() => _DeleteAccountFlowState();
}

class _DeleteAccountFlowState extends State<DeleteAccountFlow> {
  int _step = 0;
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSize(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(duration: reduce ? Duration.zero : const Duration(milliseconds: 200), child: _step == 0 ? _first(context) : _second(context)),
    );
  }

  Widget _heading(BuildContext context, String title, String message) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: context.text.titleLarge),
      const SizedBox(height: 6),
      Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.labelSecondary)),
      const SizedBox(height: 20),
    ],
  );

  Widget _first(BuildContext context) {
    final c = context.colors;
    Widget item(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.labelSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: context.text.bodyLarge)),
        ],
      ),
    );

    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, 'Delete account?', 'This permanently erases from this device:'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              item(Icons.water_drop_outlined, 'All logged periods and notes'),
              item(Icons.tune_rounded, 'Your settings and reminders'),
              item(Icons.insights_outlined, 'Your history and predictions'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Continue', style: AppButtonStyle.destructive, onPressed: () => setState(() => _step = 1)),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Cancel', style: AppButtonStyle.quiet, onPressed: () => Navigator.of(context).pop(false)),
      ],
    );
  }

  Widget _second(BuildContext context) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, 'This can\'t be undone', 'There is no cloud copy. Unless you saved a backup file, your data is gone for good.'),
        Semantics(
          checked: _understood,
          label: 'I understand',
          child: Pressable(
            onTap: () => setState(() => _understood = !_understood),
            pressedScale: 0.985,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _CheckBox(checked: _understood),
                  const SizedBox(width: 14),
                  Expanded(child: Text('I understand', style: context.text.bodyLarge)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Delete everything', style: AppButtonStyle.danger, onPressed: _understood ? () => Navigator.of(context).pop(true) : null),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Keep my data', style: AppButtonStyle.quiet, onPressed: () => Navigator.of(context).pop(false)),
      ],
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool checked;
  const _CheckBox({required this.checked});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? c.late : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: checked ? c.late : c.labelTertiary, width: 2),
      ),
      child: AnimatedOpacity(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
        opacity: checked ? 1 : 0,
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}
