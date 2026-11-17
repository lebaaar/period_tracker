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
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/primary_button.dart';
import 'package:period_tracker/widgets/stepper_field.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 3;

  final PageController _controller = PageController();
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  int _currentPage = 0;
  int _periodLength = kDefaultPeriodLength;
  int _cycleLength = kDefaultCycleLength;
  DateTime? _lastPeriodDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _goTo(int page) {
    FocusScope.of(context).unfocus();
    return _controller.animateToPage(
      page,
      duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_currentPage < _pageCount - 1) {
      await _goTo(_currentPage + 1);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_lastPeriodDate == null || _saving) return;
    setState(() => _saving = true);

    // Read providers up front; no context use after awaits.
    final UserProvider userProvider = context.read<UserProvider>();
    final PeriodProvider periodProvider = context.read<PeriodProvider>();
    final SettingsProvider settingsProvider = context.read<SettingsProvider>();
    final UnlocksProvider unlocksProvider = context.read<UnlocksProvider>();
    final GoRouter router = GoRouter.of(context);

    // Save onboarding data
    await setOnboardingValue(true);

    // Save user to database
    await userProvider.insertUser(
      User(
        id: 1,
        name: _nameController.text.trim(),
        cycleLength: _cycleLength,
        periodLength: _periodLength,
        partnerPhoneNumber: null,
        partnerMessageHeading: kDefaultPartnerMessageHeading,
      ),
    );
    await userProvider.fetchUser();

    // Set initial period
    final DateTime start = DateTime.utc(_lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);
    final DateTime end = start.add(Duration(days: _periodLength - 1));
    await periodProvider.insertPeriod(Period(startDate: start, endDate: end, notes: ''));
    await periodProvider.fetchPeriods();

    // Request notification permission
    final bool result = await NotificationService().requestPermissions();

    await settingsProvider.insertSettings(
      Settings(
        id: 1,
        predictionMode: 'dynamic',
        darkMode: true,
        notificationsEnabled: result,
        notificationDaysBefore: 3,
        notificationTime: const TimeOfDay(hour: 8, minute: 0),
      ),
    );
    await settingsProvider.loadSettings();

    // schedule notifications for next period
    final User? user = userProvider.user;
    final Settings? settings = settingsProvider.settings;
    final DateTime? nextPeriodStartDate = periodProvider.getNextPeriodDate(settings?.predictionMode == 'dynamic', user?.cycleLength);

    if (nextPeriodStartDate != null && settings != null) {
      await NotificationService().scheduleNotificationsForNextPeriod(nextPeriodStartDate, settings.notificationDaysBefore, settings.notificationTime);
    }

    // Disable version details by default
    await unlocksProvider.setVersionDetails(false);

    // Hide easter eggs
    await unlocksProvider.setAnimalGenerator(false);

    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bool last = _currentPage == _pageCount - 1;

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_currentPage - 1);
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Column(
            children: [
              _Header(page: _currentPage, count: _pageCount, onBack: _currentPage > 0 ? () => _goTo(_currentPage - 1) : null),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [_namePage(), _cyclePage(), _datePage()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: PrimaryButton(label: last ? 'Get started' : 'Continue', onPressed: (last && (_lastPeriodDate == null || _saving)) ? null : _next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.headlineLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: context.text.bodyLarge?.copyWith(color: context.colors.labelSecondary)),
        ],
      ),
    );
  }

  Widget _namePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Welcome', 'A private, simple period tracker. Everything stays on your phone.'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'What should we call you?'),
              onSubmitted: (_) => _next(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Pressable(
              onTap: () => context.go('/onboarding/restore'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Text('Restore from a backup', style: context.text.titleSmall?.copyWith(color: context.colors.labelSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cyclePage() {
    final c = context.colors;
    Widget card(String label, String hint, Widget stepper) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.titleMedium),
          const SizedBox(height: 2),
          Text(hint, style: context.text.bodySmall),
          const SizedBox(height: 12),
          stepper,
        ],
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Your cycle', 'Rough averages are fine. You can change them anytime.'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                card(
                  'Period length',
                  'How many days it usually lasts',
                  StepperField(value: _periodLength, min: kMinPeriodLength, max: kMaxPeriodLength, onChanged: (v) => setState(() => _periodLength = v)),
                ),
                card(
                  'Cycle length',
                  'First day of one period to the first day of the next',
                  StepperField(value: _cycleLength, min: kMinCycleLength, max: kMaxCycleLength, onChanged: (v) => setState(() => _cycleLength = v)),
                ),
                Pressable(
                  onTap: () => showInfo(
                    context: context,
                    title: 'Period vs. cycle',
                    message:
                        'Period length is the number of days you bleed (for example 5).\n\nCycle length is the number of days from the first day of one period to the first day of the next (for example 28).',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('What\'s the difference?', style: context.text.titleSmall?.copyWith(color: c.labelSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePage() {
    final c = context.colors;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Last period', 'Tap the day your last period started.'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(20)),
              child: CalendarDatePicker(
                initialDate: _lastPeriodDate ?? clock.now(),
                firstDate: kFirstCalendarDay,
                lastDate: clock.now(),
                onDateChanged: (picked) => setState(() => _lastPeriodDate = picked),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              _lastPeriodDate == null ? 'No day selected yet' : 'Started ${DateFormat('d MMMM yyyy').format(_lastPeriodDate!)}',
              style: context.text.bodyMedium?.copyWith(color: c.labelSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back chevron + thin segmented progress.
class _Header extends StatelessWidget {
  final int page;
  final int count;
  final VoidCallback? onBack;
  const _Header({required this.page, required this.count, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: onBack == null ? null : IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), tooltip: 'Back', onPressed: onBack),
          ),
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 4,
                      decoration: BoxDecoration(color: i <= page ? c.accent : c.hairline, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}
