enum Days { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class QadahSettings {
  final int totalMissedDays;
  final int totalPaidDays;
  final List<Days> reminderDays;
  final DateTime reminderTime;
  final bool remindersEnabled;

  const QadahSettings({
    this.totalMissedDays = 0,
    this.totalPaidDays = 0,
    this.reminderDays = const [],
    required this.reminderTime,
    this.remindersEnabled = false,
  });

  int get remainingDays => totalMissedDays - totalPaidDays;

  QadahSettings copyWith({
    int? totalMissedDays,
    int? totalPaidDays,
    List<Days>? reminderDays,
    DateTime? reminderTime,
    bool? remindersEnabled,
  }) {
    return QadahSettings(
      totalMissedDays: totalMissedDays ?? this.totalMissedDays,
      totalPaidDays: totalPaidDays ?? this.totalPaidDays,
      reminderDays: reminderDays ?? this.reminderDays,
      reminderTime: reminderTime ?? this.reminderTime,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  // To/From Map logic for persistence can go here
  Map<String, dynamic> toJson() => {
    'totalMissedDays': totalMissedDays,
    'totalPaidDays': totalPaidDays,
    'reminderDays': reminderDays.map((d) => d.index).toList(),
    'reminderTime': reminderTime.toIso8601String(),
    'remindersEnabled': remindersEnabled,
  };

  factory QadahSettings.fromJson(Map<String, dynamic> json) {
    return QadahSettings(
      totalMissedDays: json['totalMissedDays'] ?? 0,
      totalPaidDays: json['totalPaidDays'] ?? 0,
      reminderDays:
          (json['reminderDays'] as List<dynamic>?)
              ?.map((e) => Days.values[e])
              .toList() ??
          [],
      reminderTime:
          DateTime.tryParse(json['reminderTime'] ?? '') ??
          DateTime(2024, 1, 1, 20, 0), // Default 8 PM
      remindersEnabled: json['remindersEnabled'] ?? false,
    );
  }
}
