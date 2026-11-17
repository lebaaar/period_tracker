import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:period_tracker/theme.dart';

/// Thin ring showing how far through the cycle you are.
class CycleRing extends StatelessWidget {
  final double progress; // 0..1 of the cycle elapsed
  final Color? progressColor;
  final double size;
  final double stroke;
  final Widget child;

  const CycleRing({super.key, required this.progress, required this.child, this.progressColor, this.size = 232, this.stroke = 10});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(progress: value, track: c.hairline, solid: progressColor ?? c.accent, knob: c.background, stroke: stroke),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color solid;
  final Color knob;
  final double stroke;

  _RingPainter({required this.progress, required this.track, required this.solid, required this.knob, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    const double start = -math.pi / 2;

    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base..color = track);
    if (progress > 0) {
      canvas.drawArc(rect, start, 2 * math.pi * progress, false, base..color = solid);
      final double angle = start + 2 * math.pi * progress;
      final Offset p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(p, stroke / 2 + 3, Paint()..color = knob);
      canvas.drawCircle(p, stroke / 2 - 1, Paint()..color = solid);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.track != track || old.solid != solid || old.knob != knob || old.stroke != stroke;
}
