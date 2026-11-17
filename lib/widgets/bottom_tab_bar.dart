import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/pressable.dart';

class BottomTabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const BottomTabItem({required this.label, required this.icon, required this.selectedIcon});
}

/// Translucent tab bar; the selected tab is darker, no pill.
class BottomTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<BottomTabItem> items;

  const BottomTabBar({super.key, required this.index, required this.onChanged, required this.items});

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final double bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: height + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: 0.78),
            border: Border(top: BorderSide(color: c.hairline, width: 0.5)),
          ),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: items[i].label,
                    child: Pressable(
                      haptic: false,
                      pressedScale: 0.94,
                      onTap: () {
                        if (i != index) HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(i == index ? items[i].selectedIcon : items[i].icon, size: 24, color: i == index ? c.label : c.labelTertiary),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            style: context.text.labelSmall?.copyWith(
                              color: i == index ? c.label : c.labelTertiary,
                              letterSpacing: 0.1,
                              fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
