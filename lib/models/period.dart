class Period {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;

  Period({this.id, required this.startDate, this.endDate});

  bool get isOngoing => endDate == null;
  bool get isCompleted => endDate != null;
  Duration get duration => isOngoing
      ? DateTime.now().difference(startDate)
      : endDate!.difference(startDate);

  int lengthInDays() {
    return isOngoing
        ? DateTime.now().difference(startDate).inDays
        : endDate!.difference(startDate).inDays;
  }

  factory Period.fromMap(Map<String, dynamic> map) {
    return Period(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Period(startDate: $startDate, endDate: $endDate, duration: $duration)';
  }
}
