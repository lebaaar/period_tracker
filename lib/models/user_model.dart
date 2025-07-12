class User {
  final int? id;
  final String? name;
  final int cycleLength;
  final int periodLength;
  final DateTime lastPeriodDate;

  User({
    this.id,
    this.name,
    required this.cycleLength,
    required this.periodLength,
    required this.lastPeriodDate,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String?,
      cycleLength: map['cycleLength'] as int,
      periodLength: map['periodLength'] as int,
      lastPeriodDate: DateTime.parse(map['lastPeriodDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? 1,
      'name': name,
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'lastPeriodDate': lastPeriodDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, cycleLength: $cycleLength, periodLength: $periodLength, lastPeriodDate: $lastPeriodDate)';
  }
}
