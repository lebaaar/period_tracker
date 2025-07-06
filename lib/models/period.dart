class Period {
  final DateTime startDate;
  final DateTime? endDate;

  Period({required this.startDate, this.endDate});

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

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Period(startDate: $startDate, endDate: $endDate, duration: $duration)';
  }
}
