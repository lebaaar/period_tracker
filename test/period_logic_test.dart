import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/models/period_model.dart';
import 'package:period_tracker/providers/period_provider.dart';

PeriodProvider _provider(List<Period> periods) {
  final PeriodProvider p = PeriodProvider.test();
  p.setPeriodsForTest(periods);
  return p;
}

Period _p(int y, int m, int d, {int len = 5}) => Period(startDate: DateTime.utc(y, m, d), endDate: DateTime.utc(y, m, d + len - 1));

void main() {
  group('Period dates', () {
    test('old UTC rows keep their calendar day', () {
      final Period p = Period.fromMap({'startDate': '2026-03-05T00:00:00.000Z', 'endDate': '2026-03-09T00:00:00.000Z'});
      expect(p.startDate, DateTime.utc(2026, 3, 5));
      expect(p.endDate, DateTime.utc(2026, 3, 9));
    });

    test('old local rows (no Z, with time) keep their calendar day', () {
      final Period p = Period.fromMap({'startDate': '2026-03-05T23:30:00.000', 'endDate': '2026-03-09T00:00:00.000'});
      expect(p.startDate, DateTime.utc(2026, 3, 5));
      expect(p.endDate, DateTime.utc(2026, 3, 9));
    });

    test('toMap writes UTC midnight and round-trips', () {
      final Period p = Period(startDate: DateTime(2026, 3, 5, 18, 45), endDate: DateTime(2026, 3, 8, 9));
      expect(p.toMap()['startDate'], '2026-03-05T00:00:00.000Z');
      expect(Period.fromMap(p.toMap()).startDate, p.startDate);
    });
  });

  group('predictions', () {
    final List<Period> history = [_p(2026, 1, 1), _p(2026, 1, 29), _p(2026, 2, 28)]; // cycles 28, 30

    test('order of calls does not change results', () {
      final PeriodProvider a = _provider(history);
      final double? first = a.getAveragePeriodLength(useRecent6: true);
      a.getNextPeriodDate(true, 28);
      a.getCurrentCycleDay(DateTime.utc(2026, 3, 1));
      expect(a.getAveragePeriodLength(useRecent6: true), first);
      expect(a.periods.first.startDate, DateTime.utc(2026, 2, 28));
    });

    test('recent 6 uses the newest periods', () {
      final List<Period> many = [
        for (int i = 0; i < 8; i++) Period(startDate: DateTime.utc(2025, 1, 1).add(Duration(days: i * 28)), endDate: DateTime.utc(2025, 1, 1).add(Duration(days: i * 28 + (i < 2 ? 1 : 4)))),
      ];
      expect(_provider(many).getAveragePeriodLength(useRecent6: true), 5); // newest 6 are all 5 days
    });

    test('next 3 dates are evenly spaced', () {
      final List<DateTime> d = _provider(history).getNext3PeriodDates(true, 28);
      expect(d[1].difference(d[0]).inDays, d[2].difference(d[1]).inDays);
      expect(d[0], DateTime.utc(2026, 2, 28).add(const Duration(days: 29)));
    });

    test('single period falls back to user cycle length', () {
      expect(_provider([_p(2026, 1, 1)]).getNextPeriodDate(true, 30), DateTime.utc(2026, 1, 31));
    });

    test('cycle day', () {
      final PeriodProvider p = _provider(history);
      expect(p.getCurrentCycleDay(DateTime.utc(2026, 2, 28)), 1);
      expect(p.getCurrentCycleDay(DateTime.utc(2026, 3, 4)), 5);
      expect(p.getCurrentCycleDay(DateTime.utc(2025, 12, 1)), 0);
    });
  });
}
