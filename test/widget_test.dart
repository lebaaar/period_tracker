import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/main.dart';

void main() {
  testWidgets('shows onboarding as the initial app route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const PeriodTrackerApp(showOnboarding: true, isAfterRestore: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Restore data'), findsOneWidget);
  });
}
