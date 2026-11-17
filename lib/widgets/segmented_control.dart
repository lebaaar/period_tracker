import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:period_tracker/theme.dart';

class SegmentOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  const SegmentOption({required this.value, required this.label, this.icon});
}

/// Pill segmented control with a sliding thumb. [onCard] picks the track colour inside a
/// [GroupedSection]. The thumb is neutral so pink stays for primary actions.
class SegmentedControl<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool onCard;

  const SegmentedControl({super.key, required this.options, required this.selected, required this.onChanged, this.onCard = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final int index = options.indexWhere((o) => o.value == selected).clamp(0, options.length - 1);

    final Color track = onCard ? c.background : (dark ? c.card : c.hairline.withValues(alpha: 0.7));
    final Color thumb = dark ? c.elevated : c.card;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(99)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment(options.length == 1 ? 0 : -1 + 2 * index / (options.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / options.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: thumb,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: dark ? null : const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (int i = 0; i < options.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: options[i].label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i == index) return;
                        HapticFeedback.selectionClick();
                        onChanged(options[i].value);
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (options[i].icon != null) ...[
                              Icon(options[i].icon, size: 18, color: i == index ? c.label : c.labelSecondary),
                              const SizedBox(width: 6),
                            ],
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: context.text.titleSmall!.copyWith(
                                color: i == index ? c.label : c.labelSecondary,
                                fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                              ),
                              child: Text(options[i].label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
