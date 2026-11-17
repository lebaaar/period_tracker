import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Press feedback: scales down on pointer-down and springs back.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final HitTestBehavior behavior;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  // response 0.3s, damping ratio 1.0
  static final SpringDescription _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 438, ratio: 1.0);

  late final AnimationController _controller = AnimationController.unbounded(vsync: this, value: 1);

  void _animateTo(double target) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    _controller.animateWith(SpringSimulation(_spring, _controller.value, target, _controller.velocity));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _animateTo(widget.pressedScale) : null,
      onTapCancel: enabled ? () => _animateTo(1) : null,
      onTapUp: enabled ? (_) => _animateTo(1) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}
