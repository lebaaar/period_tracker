import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:table_calendar/table_calendar.dart';

enum _RunKind { draft, logged, muted, predicted }

class _Run {
  final _RunKind kind;
  final bool isStart;
  final bool isEnd;
  const _Run(this.kind, this.isStart, this.isEnd);
}

/// Calendar for Today (select a day) and Log (pick a range).
class PeriodCalendar extends StatefulWidget {
  final DateTime initialFocusedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final List<Period> periods;
  final List<DateTime> predictedStarts;
  final int predictedLength;

  /// Single-select mode (Today).
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;

  /// Range mode (Log). Set [onRangeSelected] to pick ranges.
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final void Function(DateTime? start, DateTime? end)? onRangeSelected;

  /// Draw [periods] muted so they don't compete with the range being edited.
  final bool mutedPeriods;
  final bool showLegend;

  const PeriodCalendar({
    super.key,
    required this.initialFocusedDay,
    required this.firstDay,
    required this.lastDay,
    this.periods = const [],
    this.predictedStarts = const [],
    this.predictedLength = 5,
    this.selectedDay,
    this.onDaySelected,
    this.rangeStart,
    this.rangeEnd,
    this.onRangeSelected,
    this.mutedPeriods = false,
    this.showLegend = true,
  });

  @override
  State<PeriodCalendar> createState() => _PeriodCalendarState();
}

class _PeriodCalendarState extends State<PeriodCalendar> {
  late DateTime _focused = widget.initialFocusedDay;

  bool get _rangeMode => widget.onRangeSelected != null;

  DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  void _shiftMonth(int delta) {
    final DateTime next = DateTime(_focused.year, _focused.month + delta, 1);
    if (next.isBefore(DateTime(widget.firstDay.year, widget.firstDay.month, 1)) || next.isAfter(widget.lastDay)) return;
    setState(() => _focused = next);
  }

  _Run? _runOf(DateTime day) {
    final DateTime d = _utc(day);

    if (_rangeMode && widget.rangeStart != null) {
      final DateTime s = _utc(widget.rangeStart!);
      final DateTime e = _utc(widget.rangeEnd ?? widget.rangeStart!);
      if (DateTimeHelper.dayBetweenDates(d, s, e)) return _Run(_RunKind.draft, d == s, d == e);
    }

    for (final Period p in widget.periods) {
      if (p.endDate == null) continue;
      final DateTime s = _utc(p.startDate);
      final DateTime e = _utc(p.endDate!);
      if (DateTimeHelper.dayBetweenDates(d, s, e)) return _Run(widget.mutedPeriods ? _RunKind.muted : _RunKind.logged, d == s, d == e);
    }

    for (final DateTime start in widget.predictedStarts) {
      final DateTime s = _utc(start);
      final DateTime e = s.add(Duration(days: widget.predictedLength - 1));
      if (DateTimeHelper.dayBetweenDates(d, s, e)) return _Run(_RunKind.predicted, d == s, d == e);
    }
    return null;
  }

  Widget _cell(BuildContext context, DateTime day) {
    final c = context.colors;
    final _Run? run = _runOf(day);
    final bool selected = widget.selectedDay != null && isSameDay(widget.selectedDay, day);
    final bool today = isSameDay(day, DateTime.now());

    final bool roundLeft = run != null && (run.isStart || day.weekday == DateTime.monday || day.day == 1);
    final bool roundRight = run != null && (run.isEnd || day.weekday == DateTime.sunday || DateTimeHelper.isLastDayOfMonth(day));

    Color? runColor;
    Color textColor = c.label;
    if (run != null) {
      switch (run.kind) {
        case _RunKind.draft:
          // Range being picked: soft tint between solid end circles.
          // Opaque: translucent cells would show darker seams where they overlap.
          runColor = Color.alphaBlend(c.accent.withValues(alpha: 0.32), c.card);
          textColor = (run.isStart || run.isEnd) ? c.onAccent : c.label;
        case _RunKind.logged:
          runColor = c.accent;
          textColor = c.onAccent;
        case _RunKind.muted:
          runColor = c.hairline;
        case _RunKind.predicted:
          runColor = Color.alphaBlend(c.accentSoft, c.card);
      }
    }

    if (selected) textColor = c.background; // inverted on the selection circle

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (run != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) {
                  final double w = box.maxWidth;
                  // A circle on top (selected day or range end) must not have the band's rounded cap
                  // under it, or the edge peeks out. On capped sides the band stops at the cell centre.
                  final bool circle = selected || (run.kind == _RunKind.draft && (run.isStart || run.isEnd));
                  final bool cutLeft = circle && roundLeft;
                  final bool cutRight = circle && roundRight;
                  final double left = cutLeft ? w / 2 : (roundLeft ? 5 : -0.5); // -0.5 overlaps neighbours: no hairline seams
                  final double right = cutRight ? w / 2 : (roundRight ? 5 : -0.5);
                  if (left >= w - right) return const SizedBox.shrink(); // only the circle remains
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 6,
                        bottom: 6,
                        left: left,
                        right: right,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: runColor,
                            borderRadius: BorderRadius.horizontal(
                              left: (roundLeft && !cutLeft) ? const Radius.circular(18) : Radius.zero,
                              right: (roundRight && !cutRight) ? const Radius.circular(18) : Radius.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (run?.kind == _RunKind.draft && (run!.isStart || run.isEnd))
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
              ),
            ),
          if (selected)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.label),
            ),
          Text(
            '${day.day}',
            style: context.text.bodyMedium?.copyWith(color: textColor, fontWeight: (today || selected) ? FontWeight.w700 : FontWeight.w400),
          ),
          if (today)
            Positioned(
              bottom: 8,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // inverts on the selection circle; dark on a solid band; otherwise accent
                  color: selected ? c.background : ((run?.kind == _RunKind.logged || run?.kind == _RunKind.draft) ? c.onAccent : c.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final DateTime now = DateTime.now();
    final bool onCurrentMonth = _focused.year == now.year && _focused.month == now.month;
    Widget builder(BuildContext ctx, DateTime day, DateTime focused) => _cell(ctx, day);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Align(
                      key: ValueKey('${_focused.year}-${_focused.month}'),
                      alignment: Alignment.centerLeft,
                      child: Text(DateFormat('MMMM yyyy').format(_focused), style: context.text.titleMedium),
                    ),
                  ),
                ),
                if (!onCurrentMonth)
                  Pressable(
                    onTap: () => setState(() => _focused = DateTime.now()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text('Today', style: context.text.titleSmall?.copyWith(color: c.labelSecondary)),
                    ),
                  ),
                _ChevronButton(icon: Icons.chevron_left_rounded, label: 'Previous month', onTap: () => _shiftMonth(-1)),
                _ChevronButton(icon: Icons.chevron_right_rounded, label: 'Next month', onTap: () => _shiftMonth(1)),
              ],
            ),
          ),
          TableCalendar(
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.monday,
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
            focusedDay: _focused,
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            rowHeight: 48,
            daysOfWeekHeight: 28,
            selectedDayPredicate: _rangeMode ? null : (day) => widget.selectedDay != null && isSameDay(widget.selectedDay, day),
            rangeSelectionMode: _rangeMode ? RangeSelectionMode.toggledOn : RangeSelectionMode.toggledOff,
            rangeStartDay: widget.rangeStart,
            rangeEndDay: widget.rangeEnd,
            onDaySelected: (selected, focused) {
              setState(() => _focused = focused);
              if (!_rangeMode) widget.onDaySelected?.call(selected);
            },
            onRangeSelected: (start, end, focused) {
              setState(() => _focused = focused);
              widget.onRangeSelected?.call(start, end);
            },
            onPageChanged: (focused) => setState(() => _focused = focused),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: context.text.labelSmall!.copyWith(color: c.labelTertiary, letterSpacing: 0.4),
              weekendStyle: context.text.labelSmall!.copyWith(color: c.labelTertiary, letterSpacing: 0.4),
              dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).substring(0, 1).toUpperCase(),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.zero,
              tablePadding: EdgeInsets.zero,
              rangeHighlightColor: Colors.transparent,
              isTodayHighlighted: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: builder,
              todayBuilder: builder,
              selectedBuilder: builder,
              rangeStartBuilder: builder,
              rangeEndBuilder: builder,
              withinRangeBuilder: builder,
              rangeHighlightBuilder: (context, day, isWithinRange) => const SizedBox.shrink(),
            ),
          ),
          if (widget.showLegend)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _LegendDot(color: c.accent, label: _rangeMode ? 'Selected' : 'Period'),
                  const SizedBox(width: 16),
                  if (!_rangeMode) _LegendDot(color: c.accentSoft, label: 'Predicted'),
                  if (_rangeMode && widget.periods.isNotEmpty) _LegendDot(color: c.hairline, label: 'Logged'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChevronButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 26, color: context.colors.labelSecondary)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}
