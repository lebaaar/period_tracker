class User {
  final int? id;
  final String? name;
  final int cycleLength;
  final int periodLength;
  final String? partnerPhoneNumber; // SI|+386|12345678
  final String? partnerMessageHeading;

  User({this.id, this.name, required this.cycleLength, required this.periodLength, this.partnerPhoneNumber, this.partnerMessageHeading});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String?,
      cycleLength: map['cycleLength'] as int,
      periodLength: map['periodLength'] as int,
      partnerPhoneNumber: map['partnerPhoneNumber'] as String?,
      partnerMessageHeading: map['partnerMessageHeading'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? 1,
      'name': name,
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'partnerPhoneNumber': partnerPhoneNumber,
      'partnerMessageHeading': partnerMessageHeading,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, cycleLength: $cycleLength, periodLength: $periodLength, partnerPhoneNumber: $partnerPhoneNumber, partnerMessageHeading: $partnerMessageHeading)';
  }
}
