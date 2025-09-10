class Period {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  Period({this.id, required this.startDate, this.endDate, this.notes});

  bool get isOngoing => endDate == null;
  bool get isCompleted => endDate != null;
  Duration get duration => isOngoing
      ? DateTime.now().toUtc().difference(startDate)
      : endDate!.difference(startDate);

  factory Period.fromMap(Map<String, dynamic> map) {
    return Period(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'Period(startDate: $startDate, endDate: $endDate, duration: $duration, notes: $notes)';
  }
}
