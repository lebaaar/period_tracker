import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/providers/settings_provider.dart';
import 'package:period_tracker/providers/user_provider.dart';
import 'package:period_tracker/services/notification_service.dart';
import 'package:period_tracker/services/period_service.dart';
import 'package:period_tracker/shared_preferences/shared_preferences.dart';
import 'package:period_tracker/utils/date_time_helper.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _cycleLengthController;
  late final TextEditingController _periodLengthController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _periodLengthFocusNode;
  late final FocusNode _cycleLengthFocusNode;
  DateTime? _lastPeriodDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _cycleLengthController = TextEditingController();
    _periodLengthController = TextEditingController();
    _nameFocusNode = FocusNode();
    _periodLengthFocusNode = FocusNode();
    _cycleLengthFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    _nameFocusNode.dispose();
    _periodLengthFocusNode.dispose();
    _cycleLengthFocusNode.dispose();
    super.dispose();
  }

  bool validateInput() {
    final cycleLength = int.tryParse(_cycleLengthController.text);
    final periodLength = int.tryParse(_periodLengthController.text);

    final bool periodValid = PeriodService.validatePeriodLength(periodLength);
    final bool cycleValid = PeriodService.validateCycleLength(cycleLength);

    if (!periodValid) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid period length.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (!cycleValid) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid cycle length.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return true;
  }

  Widget _buildNameInputPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Let\'s start with your name',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
              _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
              // Move focus to the period length input and open keyboard
              FocusScope.of(context).requestFocus(_periodLengthFocusNode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCycleInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Cycle Info', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Enter your cycle and period lengths in days',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _periodLengthController,
            focusNode: _periodLengthFocusNode,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            decoration: InputDecoration(
              hintText: 'Average period length',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_cycleLengthFocusNode);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cycleLengthController,
            focusNode: _cycleLengthFocusNode,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            decoration: InputDecoration(
              hintText: 'Average cycle length',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kBorderRadius),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              bool isValid = validateInput();
              if (!isValid) {
                // Keep focus and keyboard open
                FocusScope.of(context).requestFocus(_cycleLengthFocusNode);
                SystemChannels.textInput.invokeMethod('TextInput.show');
                return;
              }
              FocusScope.of(context).unfocus();
              _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLastPeriodDatePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Last Period',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Select the date your last period started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              FocusScope.of(context).unfocus();
              return CalendarDatePicker(
                initialDate: _lastPeriodDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                onDateChanged: (picked) {
                  setState(() {
                    _lastPeriodDate = picked;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _lastPeriodDate == null
                ? 'No date selected'
                : 'My last period started ${DateTimeHelper.displayDate(_lastPeriodDate!)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildNameInputPage(),
            _buildCycleInfoPage(),
            _buildLastPeriodDatePage(),
          ],
        ),
        bottomSheet: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              TextButton(
                onPressed: () {
                  switch (_currentPage) {
                    case 1:
                      FocusScope.of(context).requestFocus(_nameFocusNode);
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeIn,
                      );
                      break;
                    case 2:
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeIn,
                      );
                      break;
                  }
                },
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.all(4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                switch (_currentPage) {
                  case 0:
                    FocusScope.of(context).requestFocus(_periodLengthFocusNode);
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                    break;
                  case 1:
                    if (!validateInput()) return;

                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                    break;
                  case 2:
                    // Validate input
                    if (context.mounted) {
                      if (_lastPeriodDate == null) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select the start day of your last period.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                    }

                    // Save onboarding data
                    await setOnboardingValue(true);

                    // Save user to database
                    if (context.mounted) {
                      await context.read<UserProvider>().insertUser(
                        User(
                          id: 1,
                          name: _nameController.text.trim(),
                          cycleLength: int.parse(_cycleLengthController.text),
                          periodLength: int.parse(_periodLengthController.text),
                          lastPeriodDate: _lastPeriodDate!,
                        ),
                      );
                    }

                    // Set initial period
                    final DateTime start = DateTime.utc(
                      _lastPeriodDate!.year,
                      _lastPeriodDate!.month,
                      _lastPeriodDate!.day,
                    );
                    final DateTime end = start.add(
                      Duration(
                        days: int.parse(_periodLengthController.text) - 1,
                      ),
                    );

                    final period = Period(
                      startDate: start,
                      endDate: end,
                      notes: '',
                    );

                    await context.read<PeriodProvider>().insertPeriod(period);
                    await context.read<PeriodProvider>().fetchPeriods();
                    await context.read<SettingsProvider>().loadSettings();

                    // Request notification permission
                    await NotificationService().requestPermissions();
                    // TODO: handle permission denied

                    // Navigate to home screen
                    if (context.mounted) {
                      context.go('/');
                    }
                    break;
                }
              },
              child: Text(_currentPage < 2 ? 'Next' : 'Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
