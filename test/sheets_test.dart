import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/delete_account_sheet.dart';
import 'package:period_tracker/widgets/order_boyfriend_fields.dart';

/// Pumps ~60fps frames so mid-animation rebuilds happen.
Future<void> frames(WidgetTester tester, {int ms = 800}) async {
  for (int t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void setKeyboard(WidgetTester tester, double logicalHeight) {
  tester.view.viewInsets = FakeViewPadding(bottom: logicalHeight * tester.view.devicePixelRatio);
}

Widget app(Future<void> Function(BuildContext) opener) => MaterialApp(
  theme: lightTheme,
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(onPressed: () => opener(context), child: const Text('open')),
      ),
    ),
  ),
);

void main() {
  panelTests();

  testWidgets('text sheet: typing, keyboard opening and closing while it animates out, returns the text', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    String? result;
    await tester.pumpWidget(
      app((context) async {
        result = await showTextSheet(context: context, title: 'Order boyfriend message', initial: 'Hi', maxLines: 4);
      }),
    );

    await tester.tap(find.text('open'));
    await frames(tester);
    setKeyboard(tester, 300); // autofocus brings the keyboard up
    await frames(tester, ms: 400);

    await tester.enterText(find.byType(TextField), 'New heading');
    await tester.pump();

    await tester.tap(find.text('Save'));
    setKeyboard(tester, 0); // keyboard goes away while the sheet is closing
    await frames(tester, ms: 1000);

    expect(tester.takeException(), isNull);
    expect(result, 'New heading');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('order boyfriend sheet: type phone + message, send, dismiss with keyboard animating', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    String number = '';
    String message = '';
    await tester.pumpWidget(
      app(
        (context) => showAppSheet<void>(
          context: context,
          title: 'Order boyfriend',
          actionLabel: 'Send',
          builder: (_) => OrderBoyfriendFields(
            initialIsoCode: 'SI',
            initialNumber: '',
            onPhoneChanged: (iso, dial, value) => number = value,
            onMessageChanged: (value) => message = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await frames(tester);
    expect(tester.takeException(), isNull, reason: 'opening the sheet');

    final Finder fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    await tester.tap(fields.first);
    setKeyboard(tester, 300);
    await frames(tester, ms: 400);
    await tester.enterText(fields.first, '41234567');
    await tester.pump();

    await tester.tap(fields.last);
    await frames(tester, ms: 200);
    await tester.enterText(fields.last, 'Please bring chocolate');
    await tester.pump();

    expect(number, '41234567');
    expect(message, 'Please bring chocolate');

    await tester.tap(find.text('Send'));
    setKeyboard(tester, 0);
    await frames(tester, ms: 1000);

    expect(tester.takeException(), isNull, reason: 'closing with the keyboard animating');
    expect(find.byType(OrderBoyfriendFields), findsNothing);
  });

  testWidgets('order boyfriend sheet can be opened and dismissed repeatedly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(
        (context) => showAppSheet<void>(
          context: context,
          title: 'Order boyfriend',
          actionLabel: 'Send',
          builder: (_) => OrderBoyfriendFields(initialIsoCode: 'SI', initialNumber: '', onPhoneChanged: (_, _, _) {}, onMessageChanged: (_) {}),
        ),
      ),
    );

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('open'));
      await frames(tester);
      await tester.tap(find.byType(TextField).first);
      setKeyboard(tester, 300);
      await frames(tester, ms: 300);
      setKeyboard(tester, 0);
      await tester.tapAt(const Offset(180, 40)); // tap the scrim
      await frames(tester, ms: 800);
      expect(tester.takeException(), isNull, reason: 'round $i');
    }
  });
}

void panelTests() {
  testWidgets('confirm is a bottom panel (not a dialog) and resolves true / false', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(
      app((context) async {
        result = await showConfirm(context: context, title: 'Delete period?', message: 'Gone.', confirmLabel: 'Delete', destructive: true);
      }),
    );

    await tester.tap(find.text('open'));
    await frames(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    // sheet sits at the bottom edge
    final double sheetBottom = tester.getBottomLeft(find.byType(BottomSheet)).dy;
    expect(sheetBottom, closeTo(tester.view.physicalSize.height / tester.view.devicePixelRatio, 0.5));

    await tester.tap(find.text('Delete'));
    await frames(tester);
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await frames(tester);
    await tester.tap(find.text('Cancel'));
    await frames(tester);
    expect(result, isFalse);
  });

  testWidgets('confirm dialog is a centred modal (not a bottom panel) and resolves true / false', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(
      app((context) async {
        result = await showConfirmDialog(context: context, title: 'Get reminders on time', message: 'Allow alarms.', confirmLabel: 'Open settings', cancelLabel: 'Not now');
      }),
    );

    await tester.tap(find.text('open'));
    await frames(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    final double screenH = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getCenter(find.byType(Dialog)).dy, closeTo(screenH / 2, 1));

    await tester.tap(find.text('Open settings'));
    await frames(tester);
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await frames(tester);
    await tester.tap(find.text('Not now'));
    await frames(tester);
    expect(result, isFalse);
  });

  testWidgets('inputs inside a sheet are visibly different from the sheet surface', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      app(
        (context) => showAppSheet<void>(
          context: context,
          title: 'Name',
          builder: (_) => const TextField(decoration: InputDecoration(hintText: 'Name')),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await frames(tester);

    final inputs = Theme.of(tester.element(find.byType(TextField))).inputDecorationTheme;
    final AppColors colors = AppColors.light;
    expect(inputs.fillColor, isNot(colors.card), reason: 'fill must differ from the sheet colour');
    expect((inputs.enabledBorder as OutlineInputBorder).borderSide.width, greaterThan(0), reason: 'has a visible border');
  });

  testWidgets('select sheet returns the tapped option', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    String? picked;
    await tester.pumpWidget(
      app((context) async {
        picked = await showSelectSheet<String>(
          context: context,
          title: 'Sort history',
          selected: 'a',
          options: const [
            SelectOption(value: 'a', label: 'Newest first'),
            SelectOption(value: 'b', label: 'Oldest first'),
          ],
        );
      }),
    );
    await tester.tap(find.text('open'));
    await frames(tester);
    await tester.tap(find.text('Oldest first'));
    await frames(tester);
    expect(picked, 'b');
  });

  testWidgets('delete account needs two steps and an explicit acknowledgement', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(app((context) async => result = await showDeleteAccountSheet(context)));

    // step 1: continuing does not delete
    await tester.tap(find.text('open'));
    await frames(tester);
    expect(find.text('Delete account?'), findsOneWidget);
    expect(find.text('Delete everything'), findsNothing);
    await tester.tap(find.text('Continue'));
    await frames(tester);
    expect(result, isNull, reason: 'still open after step 1');

    // step 2: the destructive button is disabled until acknowledged
    expect(find.byType(Switch), findsNothing, reason: 'acknowledgement is a checkbox, not a switch');
    expect(find.text('Delete everything'), findsOneWidget);
    await tester.tap(find.text('Delete everything'));
    await frames(tester);
    expect(result, isNull, reason: 'disabled until "I understand"');

    await tester.tap(find.text('I understand'));
    await frames(tester, ms: 300);
    await tester.tap(find.text('Delete everything'));
    await frames(tester);
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete account: cancelling at either step keeps the data', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(app((context) async => result = await showDeleteAccountSheet(context)));

    await tester.tap(find.text('open'));
    await frames(tester);
    await tester.tap(find.text('Cancel'));
    await frames(tester);
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await frames(tester);
    await tester.tap(find.text('Continue'));
    await frames(tester);
    await tester.tap(find.text('Keep my data'));
    await frames(tester);
    expect(result, isFalse);
  });

  test('no dialogs, popup menus or dropdowns in the app, except showConfirmDialog in app_sheet.dart', () {
    final RegExp banned = RegExp(r'showDialog\(|AlertDialog\(|SimpleDialog\(|showTimePicker\(|showDatePicker\(|PopupMenuButton|DropdownButton|DropdownMenu');
    final List<String> offenders = [];
    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart') && f.path != 'lib/widgets/app_sheet.dart') {
        final String text = f.readAsStringSync();
        if (banned.hasMatch(text)) offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty, reason: 'use showAppSheet / showConfirm / showSelectSheet (or showConfirmDialog for interrupting prompts) instead');
  });
}
