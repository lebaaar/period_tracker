import 'package:period_tracker/utils/date_time_helper.dart';

/// A logged period. Dates are calendar days: always stored as UTC midnight, so there is no
/// time-of-day or timezone drift. Older data (UTC or local timestamps) is normalised on read
/// by keeping the calendar day it was written with, so no database migration is needed.
class Period {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  Period({this.id, required DateTime startDate, DateTime? endDate, this.notes})
    : startDate = DateTimeHelper.stripTime(startDate),
      endDate = endDate == null ? null : DateTimeHelper.stripTime(endDate);

  bool get isOngoing => endDate == null;
  bool get isCompleted => endDate != null;

  factory Period.fromMap(Map<String, dynamic> map) {
    return Period(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'startDate': startDate.toIso8601String(), 'endDate': endDate?.toIso8601String(), 'notes': notes};
  }

  @override
  String toString() {
    return 'Period(startDate: $startDate, endDate: $endDate, notes: $notes)';
  }
}
