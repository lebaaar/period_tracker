import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/stepper_field.dart';

void main() {
  sheetTests();
  testWidgets('StepperField steps and clamps within its bounds', (WidgetTester tester) async {
    int value = 5;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: StepperField(value: value, min: 4, max: 6, onChanged: (v) => setState(() => value = v)),
          ),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('6'), findsOneWidget);

    // already at max: stays put
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
  });
}

void sheetTests() {
  testWidgets('bottom sheet keeps its action clear of the system navigation bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    // simulate the Android 3-button navigation bar: 48dp of bottom inset
    const double navBar = 48 * 3;
    tester.view.padding = const FakeViewPadding(bottom: navBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: navBar);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showNumberSheet(context: context, title: 'Remind me before', initial: 3, min: 0, max: 14),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final double buttonBottom = tester.getBottomLeft(find.text('Save')).dy;
    final double screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(buttonBottom, lessThanOrEqualTo(screenHeight - 48));
  });
}
