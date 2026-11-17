import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/unlocks_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/grouped_section.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/period_calendar.dart';
import 'package:period_tracker/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class LogPeriodPage extends StatefulWidget {
  final bool isEditing;
  final Period? period;
  final DateTime? focusedDay;
  const LogPeriodPage({super.key, required this.isEditing, this.period, this.focusedDay});

  @override
  State<LogPeriodPage> createState() => _LogPeriodPageState();
}

class _LogPeriodPageState extends State<LogPeriodPage> {
  late final ScrollController _scrollController;
  late final TextEditingController _notesController;
  late final FocusNode _notesFocusNode;

  late DateTime _today;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _focusedDay;

  DateTime? _initialRangeStart;
  DateTime? _initialRangeEnd;
  String? _initialNotes;

  bool get isEditing => widget.isEditing;
  Period? get period => widget.period;

  void _onSave(BuildContext context, Settings? settings) async {
    // Check if range is selected
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a period range'), behavior: SnackBarBehavior.floating));
      return;
    }

    // Check for overlapping periods
    final periods = context.read<PeriodProvider>().periods;
    final hasOverlap = PeriodService.isOverlappingPeriod(
      _rangeStart!,
      periods,
      newEndDate: _rangeEnd,
      excludeId: isEditing && period != null ? period!.id : null,
    );
    if (hasOverlap) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('The selected period overlaps with an existing one'), behavior: SnackBarBehavior.floating));
      return;
    }

    final DateTime now = clock.now();
    final DateTime rangeStartCheck = DateTimeHelper.stripTime(_rangeStart!);
    final DateTime checkDate = DateTimeHelper.stripTime(now);

    // Check if period is in the future
    final bool isInFuture = rangeStartCheck.isAfter(checkDate);
    if (isInFuture) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The start date cannot be in the future.'), behavior: SnackBarBehavior.floating));
      return;
    }

    // Check minimum days between periods
    final List<Period> sortedPeriods = List<Period>.from(periods)..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (final Period p in sortedPeriods) {
      if (isEditing && period != null && p.id == period!.id) continue;
      final int gapBefore = _rangeStart!.difference(p.endDate ?? p.startDate).inDays;
      final int gapAfter = (p.startDate.difference(_rangeEnd!).inDays);
      if (gapBefore >= 0 && gapBefore < kMinDaysBetweenPeriods || gapAfter >= 0 && gapAfter < kMinDaysBetweenPeriods) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('There must be at least $kMinDaysBetweenPeriods days between periods'), behavior: SnackBarBehavior.floating));
        return;
      }
    }

    // Check if editing an existing period
    if (isEditing && period != null) {
      final Period updatedPeriod = Period(
        id: period!.id,
        startDate: DateTime.utc(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day),
        endDate: DateTime.utc(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day),
        notes: _notesController.text,
      );
      await context.read<PeriodProvider>().updatePeriod(updatedPeriod);
      if (!context.mounted) return;

      // nextPeriodDate changes here because an existing period is updated
      // schedule notifications for next period
      final DateTime? nextPeriodDate = context.read<PeriodProvider>().getNextPeriodDate(
        settings?.predictionMode == 'dynamic',
        context.read<UserProvider>().user?.cycleLength,
      );
      await NotificationService().scheduleNotificationsForNextPeriod(nextPeriodDate, settings!.notificationDaysBefore, settings.notificationTime);

      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    // normalize dates to UTC
    final DateTime rangeStart = DateTime.utc(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    final DateTime rangeEnd = DateTime.utc(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);

    final Period newPeriod = Period(startDate: rangeStart, endDate: rangeEnd, notes: _notesController.text);
    await context.read<PeriodProvider>().insertPeriod(newPeriod);
    if (!context.mounted) return;
    await context.read<PeriodProvider>().fetchPeriods();
    if (!context.mounted) return;

    // nextPeriodDate changes here because a new period is added
    // schedule notifications for next period
    final DateTime? nextPeriodDate = context.read<PeriodProvider>().getNextPeriodDate(
      settings?.predictionMode == 'dynamic',
      context.read<UserProvider>().user?.cycleLength,
    );
    await NotificationService().scheduleNotificationsForNextPeriod(nextPeriodDate, settings!.notificationDaysBefore, settings.notificationTime);

    if (context.mounted) Navigator.of(context).pop();
  }

  bool isPageDirty() {
    if (isEditing && period != null) {
      return _rangeStart != _initialRangeStart || _rangeEnd != _initialRangeEnd || _notesController.text != _initialNotes;
    }
    return _rangeStart != _initialRangeStart || _rangeEnd != _initialRangeEnd || _notesController.text.isNotEmpty;
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _scrollController = ScrollController();
    _notesFocusNode = FocusNode();
    _today = clock.now();

    _notesFocusNode.addListener(() {
      if (!_notesFocusNode.hasFocus) {
        _scrollToTop();
      }
    });

    final DateTime startDay = DateTimeHelper.stripTime(widget.focusedDay ?? _today);
    _focusedDay = startDay;
    _rangeStart = startDay;
    if (isEditing && period != null) {
      _rangeStart = period!.startDate;
      _rangeEnd = period!.endDate;
      _notesController.text = period!.notes ?? '';
    } else {
      // Default the end date from the usual period length.
      final User? user = context.read<UserProvider>().user;
      if (user != null) _rangeEnd = _rangeStart!.add(Duration(days: user.periodLength - 1));
    }
    _initialRangeStart = _rangeStart;
    _initialRangeEnd = _rangeEnd;
    _initialNotes = _notesController.text;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    final bool discard = await showConfirm(
      context: context,
      title: 'Discard changes?',
      message: 'Your changes to this period won\'t be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(User? user, Settings? settings) async {
    final bool confirm = await showConfirm(
      context: context,
      title: 'Delete period?',
      message: 'This removes the entry from your history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm || !mounted) return;

    final PeriodProvider provider = context.read<PeriodProvider>();
    final GoRouter router = GoRouter.of(context);
    await provider.deletePeriod(period!.id!);

    // nextPeriodDate changes here because the period was removed
    final DateTime? nextPeriodDate = provider.getNextPeriodDate(settings?.predictionMode == 'dynamic', user?.cycleLength);
    if (settings != null) {
      await NotificationService().scheduleNotificationsForNextPeriod(nextPeriodDate, settings.notificationDaysBefore, settings.notificationTime);
    }
    router.go('/');
  }

  bool get _rangeComplete => _rangeStart != null && _rangeEnd != null;

  String _summary() {
    final DateFormat f = DateFormat('d MMM');
    final int days = DateTimeHelper.stripTime(_rangeEnd!).difference(DateTimeHelper.stripTime(_rangeStart!)).inDays + 1;
    if (days == 1) return f.format(_rangeStart!);
    return '${f.format(_rangeStart!)} – ${f.format(_rangeEnd!)}';
  }

  String _summaryDetail() {
    final int days = DateTimeHelper.stripTime(_rangeEnd!).difference(DateTimeHelper.stripTime(_rangeStart!)).inDays + 1;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<UserProvider>().user;
    final Settings? settings = context.watch<SettingsProvider>().settings;
    final List<Period> others = context.watch<PeriodProvider>().periods.where((p) => !(isEditing && period != null && p.id == period!.id)).toList();
    final c = context.colors;

    return PopScope(
      canPop: !isPageDirty(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: LargeTitleScaffold(
        title: isEditing ? 'Edit period' : 'Log period',
        largeTitle: false,
        controller: _scrollController,
        bottom: PrimaryButton(label: 'Save', onPressed: () => _onSave(context, settings)),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              // Fixed height: no jump while the range is picked.
              child: SizedBox(
                height: 58,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  // AnimatedSwitcher centres by default; keep the title left-aligned
                  layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                  child: !_rangeComplete
                      ? const SizedBox.expand(key: ValueKey('empty'))
                      : Column(
                          key: ValueKey(_summary()),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_summary(), style: context.text.headlineMedium),
                            Text(_summaryDetail(), style: context.text.bodyLarge?.copyWith(color: c.labelSecondary)),
                          ],
                        ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(
              child: PeriodCalendar(
                initialFocusedDay: _focusedDay,
                firstDay: kFirstCalendarDay,
                lastDay: kLastCalendarDay,
                periods: others,
                mutedPeriods: true,
                rangeStart: _rangeStart,
                rangeEnd: _rangeEnd,
                onRangeSelected: (start, end) => setState(() {
                  _rangeStart = start == null ? null : DateTimeHelper.stripTime(start);
                  _rangeEnd = end == null ? null : DateTimeHelper.stripTime(end);
                }),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: GroupedSection(
              header: 'Notes',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _notesController,
                    focusNode: _notesFocusNode,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add notes about this period',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          if (isEditing && period != null)
            SliverToBoxAdapter(
              child: GroupedSection(
                children: [
                  GroupedRow(
                    title: 'Delete period',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    showChevron: false,
                    onTap: () => _delete(user, settings),
                  ),
                ],
              ),
            ),
          // Easter egg: scroll this far to reach the doggy generator.
          const SliverToBoxAdapter(child: SizedBox(height: 25000)),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const Text('You need a break from all that scrolling... 🐶'),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'To the doggy generator!',
                  style: AppButtonStyle.secondary,
                  expand: false,
                  onPressed: () async {
                    await context.read<UnlocksProvider>().setAnimalGenerator(true);
                    if (context.mounted) context.push('/animal');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
