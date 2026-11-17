import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/pressable.dart';

/// `− 28 days +` control. Tap or hold to repeat, clamped, haptic on every step.
class StepperField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String unit; // e.g. "day"
  final ValueChanged<int> onChanged;

  const StepperField({super.key, required this.value, required this.min, required this.max, required this.onChanged, this.unit = 'day'});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StepButton(icon: Icons.remove_rounded, enabled: value > min, onStep: () => onChanged((value - 1).clamp(min, max))),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: Text('$value', key: ValueKey(value), style: context.text.displayMedium),
            ),
            Text(value == 1 ? unit : '${unit}s', style: context.text.bodyMedium?.copyWith(color: c.labelSecondary)),
          ],
        ),
        _StepButton(icon: Icons.add_rounded, enabled: value < max, onStep: () => onChanged((value + 1).clamp(min, max))),
      ],
    );
  }
}

class _StepButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onStep;
  const _StepButton({required this.icon, required this.enabled, required this.onStep});

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;

  void _step() {
    if (!widget.enabled) {
      _stop();
      return;
    }
    HapticFeedback.selectionClick();
    widget.onStep();
  }

  void _start() {
    _step();
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 380), () {
      _timer = Timer.periodic(const Duration(milliseconds: 70), (_) => _step());
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: Pressable(
        haptic: false,
        pressedScale: 0.92,
        onTap: () {},
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.enabled ? 1 : 0.35,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.background, shape: BoxShape.circle),
            child: Icon(widget.icon, size: 28, color: c.label),
          ),
        ),
      ),
    );
  }
}

/// Pick a whole number with a stepper in a sheet. Returns the value, or null if dismissed.
Future<int?> showNumberSheet({
  required BuildContext context,
  required String title,
  String? message,
  required int initial,
  required int min,
  required int max,
  String unit = 'day',
}) async {
  int value = initial.clamp(min, max);
  bool saved = false;
  await showAppSheet<void>(
    context: context,
    title: title,
    message: message,
    actionLabel: 'Save',
    onAction: () => saved = true,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: StepperField(value: value, min: min, max: max, unit: unit, onChanged: (v) => setState(() => value = v)),
      ),
    ),
  );
  return saved ? value : null;
}
