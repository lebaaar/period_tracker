// A real 1.3.2 backup (anonymised) must load and predict correctly in the current version.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/models/settings_model.dart';
import 'package:period_tracker/models/user_model.dart';
import 'package:period_tracker/providers/period_provider.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:period_tracker/services/notification_service.dart';

Map<String, dynamic> _fixture() => jsonDecode(File('test/fixtures/backup_1_3_2.json').readAsStringSync()) as Map<String, dynamic>;

List<Period> _periods(Map<String, dynamic> backup) =>
    ((backup['database'] as Map<String, dynamic>)['periods'] as List).map((e) => Period.fromMap(e as Map<String, dynamic>)).toList();

void main() {
  final ApplicationDataService service = ApplicationDataService();

  group('1.3.2 backup is accepted', () {
    test('identified, valid and version compatible', () {
      final Map<String, dynamic> b = _fixture();
      expect(service.isJsonFromPeriodTracker(b), isTrue);
      expect(service.isBackupDataValid(b), isTrue);
      expect(service.verifyVersionCompatibility(b['databaseVersion'] as int, kDatabaseVersion), isTrue);
    });

    test('all 14 periods keep their calendar days', () {
      final Map<String, dynamic> b = _fixture();
      final List raw = (b['database'] as Map)['periods'] as List;
      final List<Period> parsed = _periods(b);
      expect(parsed, hasLength(14));
      for (int i = 0; i < raw.length; i++) {
        final DateTime s = DateTime.parse(raw[i]['startDate'] as String);
        final DateTime e = DateTime.parse(raw[i]['endDate'] as String);
        expect(parsed[i].startDate, DateTime.utc(s.year, s.month, s.day), reason: 'start of period ${raw[i]['id']}');
        expect(parsed[i].endDate, DateTime.utc(e.year, e.month, e.day), reason: 'end of period ${raw[i]['id']}');
        expect(parsed[i].startDate.isUtc && parsed[i].startDate.hour == 0, isTrue);
      }
      expect(parsed.first.startDate, DateTime.utc(2025, 9, 22));
      expect(parsed.last.endDate, DateTime.utc(2026, 10, 8));
    });

    test('user and settings (incl. unpadded "9:3") parse', () {
      final Map<String, dynamic> db = _fixture()['database'] as Map<String, dynamic>;
      final Settings s = Settings.fromMap(db['settings'] as Map<String, dynamic>);
      expect(s.notificationTime, const TimeOfDay(hour: 9, minute: 3));
      expect(s.predictionMode, 'dynamic');
      expect(s.notificationDaysBefore, 3);
      expect(s.notificationsEnabled, isTrue);
      final User u = User.fromMap(db['user'] as Map<String, dynamic>);
      expect(u.cycleLength, 30);
      expect(u.periodLength, 5);
    });
  });

  group('predictions on the 1.3.2 data (today = 2026-10-30)', () {
    late PeriodProvider p;
    setUp(() {
      p = PeriodProvider.test()..setPeriodsForTest(_periods(_fixture()));
    });

    test('cycle averages', () {
      // all 13 gaps: 27 28 31 32 29 28 28 29 29 31 29 29 27 -> 377 / 13 = 29
      expect(p.getAverageCycleLength(), 29.0);
      expect(p.getAverageCycleLength(useRecent6: true), 29.0);
      expect(p.getAveragePeriodLength(), 5.0);
    });

    test('next period dates', () {
      expect(p.getNextPeriodDate(true, 30), DateTime.utc(2026, 11, 2)); // last start 10-04 + 29
      expect(p.getNextPeriodDate(false, 30), DateTime.utc(2026, 11, 3)); // last start 10-04 + 30
      expect(p.getNext3PeriodDates(true, 30), [DateTime.utc(2026, 11, 2), DateTime.utc(2026, 12, 1), DateTime.utc(2026, 12, 30)]);
    });

    test('cycle day', () {
      expect(p.getCurrentCycleDay(DateTime.utc(2026, 10, 30)), 27);
      expect(p.getCurrentCycleDay(DateTime.utc(2026, 10, 4)), 1);
      expect(p.getCurrentCycleDay(DateTime.utc(2026, 10, 3)), 27); // still in the previous cycle (09-07 + 26 days)
      expect(p.getCurrentCycleDay(DateTime.utc(2025, 9, 1)), 0);
      // a local time of day on the same date gives the same answer
      expect(p.getCurrentCycleDay(DateTime(2026, 10, 30, 23, 59)), 27);
    });

    test('order of calls does not change anything', () {
      final double? before = p.getAveragePeriodLength(useRecent6: true);
      p.getNextPeriodDate(true, 30);
      p.getCurrentCycleDay(DateTime.utc(2026, 10, 30));
      expect(p.getAveragePeriodLength(useRecent6: true), before);
      expect(p.periods.first.startDate, DateTime.utc(2026, 10, 4));
      expect(p.periods.last.startDate, DateTime.utc(2025, 9, 22));
    });
  });

  group('reminder times', () {
    const TimeOfDay nine = TimeOfDay(hour: 9, minute: 3);
    final DateTime next = DateTime.utc(2026, 11, 2);

    test('3 days before gives ids 0..3 at the chosen time', () {
      final r = NotificationService.reminderTimes(next, 3, nine, DateTime(2026, 10, 30, 8));
      expect(r.map((e) => e.$1), [0, 1, 2, 3]);
      expect(r[0].$2, DateTime(2026, 11, 2, 9, 3));
      expect(r[3].$2, DateTime(2026, 10, 30, 9, 3));
    });

    test('prediction today: reminder kept before the time, dropped after it', () {
      final DateTime today = DateTime.utc(2026, 11, 2);
      expect(NotificationService.reminderTimes(today, 3, nine, DateTime(2026, 11, 2, 7)).map((e) => e.$1), [0]);
      expect(NotificationService.reminderTimes(today, 3, nine, DateTime(2026, 11, 2, 10)), isEmpty);
    });

    test('late period: nothing in the past is scheduled', () {
      expect(NotificationService.reminderTimes(DateTime.utc(2026, 10, 20), 3, nine, DateTime(2026, 10, 30)), isEmpty);
    });

    test('around the clock change the wall-clock time stays the same', () {
      // EU clocks go back on 2026-10-25
      final r = NotificationService.reminderTimes(DateTime.utc(2026, 10, 27), 4, nine, DateTime(2026, 10, 20));
      for (final e in r) {
        expect([e.$2.hour, e.$2.minute], [9, 3]);
      }
      expect(r.map((e) => e.$2.day), [27, 26, 25, 24, 23]);
    });

    test('month and year boundaries', () {
      final r = NotificationService.reminderTimes(DateTime.utc(2027, 1, 1), 2, nine, DateTime(2026, 12, 1));
      expect(r.map((e) => e.$2), [DateTime(2027, 1, 1, 9, 3), DateTime(2026, 12, 31, 9, 3), DateTime(2026, 12, 30, 9, 3)]);
    });
  });
}
