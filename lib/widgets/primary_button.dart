import 'package:flutter/material.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/pressable.dart';

enum AppButtonStyle { primary, secondary, quiet, destructive, danger }

/// Capsule button. One primary action per screen.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool expand;
  final bool compact; // 40dp pill for use inside cards
  final double? height; // overrides the default (54, or 40 when compact)

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.expand = true,
    this.compact = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool enabled = onPressed != null;
    final (Color bg, Color fg) = switch (style) {
      AppButtonStyle.primary => (c.accent, c.onAccent),
      AppButtonStyle.secondary => (c.card, c.label),
      AppButtonStyle.quiet => (c.background, c.label), // on cards and sheets
      AppButtonStyle.destructive => (c.late.withValues(alpha: 0.12), c.late),
      AppButtonStyle.danger => (c.late, Colors.white),
    };

    return Pressable(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: height ?? (compact ? 40 : 54),
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: compact ? 18 : 20, color: fg), SizedBox(width: compact ? 6 : 8)],
              Text(label, style: (compact ? context.text.titleSmall : context.text.labelLarge)?.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
