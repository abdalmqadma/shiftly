class WakeAlarm {
  const WakeAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    this.challengeEnabled = true,
    this.ringtonePath,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final bool challengeEnabled;
  final String? ringtonePath;

  WakeAlarm copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    bool? challengeEnabled,
    String? ringtonePath,
  }) {
    return WakeAlarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      challengeEnabled: challengeEnabled ?? this.challengeEnabled,
      ringtonePath: ringtonePath ?? this.ringtonePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'challengeEnabled': challengeEnabled,
        'ringtonePath': ringtonePath,
      };

  factory WakeAlarm.fromJson(Map<String, dynamic> json) {
    return WakeAlarm(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? 'منبّه',
      enabled: json['enabled'] as bool? ?? true,
      challengeEnabled: json['challengeEnabled'] as bool? ?? true,
      ringtonePath: json['ringtonePath'] as String?,
    );
  }

  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  int get wakeStrength => challengeEnabled ? 78 : 42;
}
