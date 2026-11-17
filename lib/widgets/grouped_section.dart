import 'package:flutter/material.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/pressable.dart';

class GroupedSection extends StatelessWidget {
  final String? header;
  final Widget? headerTrailing;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const GroupedSection({
    super.key,
    this.header,
    this.headerTrailing,
    this.footer,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final List<Widget> separated = [];
    for (int i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(height: 0.5, thickness: 0.5, color: c.hairline),
          ),
        );
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null || headerTrailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(header ?? '', style: context.text.titleSmall?.copyWith(color: c.labelSecondary)),
                  ),
                  if (headerTrailing != null) headerTrailing!,
                ],
              ),
            ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: separated),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(footer!, style: context.text.bodySmall),
            ),
        ],
      ),
    );
  }
}

class GroupedRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;
  final bool showChevron;

  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color titleColor = destructive ? c.late : (enabled ? c.label : c.labelTertiary);
    final Color secondary = enabled ? c.labelSecondary : c.labelTertiary;

    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 22, color: iconColor ?? (destructive ? c.late : secondary)), const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.bodyLarge?.copyWith(color: titleColor)),
                  if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: context.text.bodySmall?.copyWith(color: secondary))],
                ],
              ),
            ),
            if (value != null) ...[const SizedBox(width: 12), Text(value!, style: context.text.bodyLarge?.copyWith(color: secondary))],
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (onTap != null && showChevron && trailing == null && enabled) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 22, color: c.labelTertiary),
            ],
          ],
        ),
      ),
    );

    if (onTap == null || !enabled) return row;
    return Pressable(onTap: onTap, pressedScale: 0.985, child: row);
  }
}
