import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SectionTitle(this.title, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
