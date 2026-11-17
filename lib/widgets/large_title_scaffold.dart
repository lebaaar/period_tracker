import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:period_tracker/theme.dart';

/// Page with a large title that collapses into a translucent top bar on scroll.
class LargeTitleScaffold extends StatefulWidget {
  final String title;
  final Widget? subtitle; // under the large title
  final Widget? titleTrailing; // beside the large title
  final List<Widget> slivers;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom; // pinned at the bottom (primary action)
  final bool showBack;
  final bool largeTitle;
  final ScrollController? controller;
  final bool resizeToAvoidBottomInset;

  const LargeTitleScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.titleTrailing,
    this.leading,
    this.actions,
    this.bottom,
    this.showBack = true,
    this.largeTitle = true,
    this.controller,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  State<LargeTitleScaffold> createState() => _LargeTitleScaffoldState();
}

class _LargeTitleScaffoldState extends State<LargeTitleScaffold> {
  late final ScrollController _controller = widget.controller ?? ScrollController();
  double _offset = 0;

  static const double _barHeight = 56;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final double o = _controller.hasClients ? _controller.offset : 0;
    if ((o - _offset).abs() > 0.5) setState(() => _offset = o);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final double top = MediaQuery.paddingOf(context).top;
    final double collapse = widget.largeTitle ? ((_offset - 8) / 32).clamp(0.0, 1.0) : 1.0;
    final bool canPop = widget.showBack && Navigator.of(context).canPop();
    // An empty bar draws nothing and takes little room.
    final bool hasBar = widget.title.isNotEmpty || canPop || widget.leading != null || (widget.actions?.isNotEmpty ?? false);
    final double barHeight = hasBar ? _barHeight : 12;

    return Scaffold(
      backgroundColor: c.background,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(), // clamping comes from the app ScrollBehavior
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: top + barHeight)),
              if (widget.largeTitle)
                SliverToBoxAdapter(
                  child: Opacity(
                    opacity: 1 - collapse,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.title, style: context.text.headlineLarge),
                                if (widget.subtitle != null) ...[const SizedBox(height: 4), widget.subtitle!],
                              ],
                            ),
                          ),
                          if (widget.titleTrailing != null) ...[const SizedBox(width: 16), widget.titleTrailing!],
                        ],
                      ),
                    ),
                  ),
                ),
              ...widget.slivers,
              SliverToBoxAdapter(child: SizedBox(height: widget.bottom != null ? 16 : MediaQuery.paddingOf(context).bottom + 24)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: hasBar ? 24 * collapse : 0, sigmaY: hasBar ? 24 * collapse : 0),
                child: Container(
                  height: top + barHeight,
                  padding: EdgeInsets.only(top: top),
                  decoration: BoxDecoration(
                    color: c.background.withValues(alpha: hasBar ? 0.72 * collapse : 0),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: collapse,
                        child: Text(widget.title, style: context.text.titleMedium),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child:
                              widget.leading ??
                              (canPop
                                  ? IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                                      tooltip: 'Back',
                                      onPressed: () => Navigator.of(context).maybePop(),
                                    )
                                  : null),
                        ),
                      ),
                      if (widget.actions != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Row(mainAxisSize: MainAxisSize.min, children: widget.actions!),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottom == null
          ? null
          : SafeArea(
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: widget.bottom),
            ),
    );
  }
}
