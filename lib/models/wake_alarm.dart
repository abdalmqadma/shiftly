class WakeAlarm {
  const WakeAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    this.challengeEnabled = true,
    this.sleepyMeProtection = true,
    this.proofOfAwake = false,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.ringtonePath,
    this.ringtoneName = 'نغمة المنبّه الافتراضية',
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final bool challengeEnabled;
  final bool sleepyMeProtection;
  final bool proofOfAwake;
  final List<int> weekdays;
  final String? ringtonePath;
  final String ringtoneName;

  WakeAlarm copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    bool? challengeEnabled,
    bool? sleepyMeProtection,
    bool? proofOfAwake,
    List<int>? weekdays,
    String? ringtonePath,
    String? ringtoneName,
    bool clearRingtone = false,
  }) {
    return WakeAlarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      challengeEnabled: challengeEnabled ?? this.challengeEnabled,
      sleepyMeProtection: sleepyMeProtection ?? this.sleepyMeProtection,
      proofOfAwake: proofOfAwake ?? this.proofOfAwake,
      weekdays: weekdays ?? this.weekdays,
      ringtonePath: clearRingtone ? null : ringtonePath ?? this.ringtonePath,
      ringtoneName: ringtoneName ?? this.ringtoneName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'challengeEnabled': challengeEnabled,
        'sleepyMeProtection': sleepyMeProtection,
        'proofOfAwake': proofOfAwake,
        'weekdays': weekdays,
        'ringtonePath': ringtonePath,
        'ringtoneName': ringtoneName,
      };

  factory WakeAlarm.fromJson(Map<String, dynamic> json) {
    final rawDays = json['weekdays'] as List<dynamic>?;
    return WakeAlarm(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? 'منبّه',
      enabled: json['enabled'] as bool? ?? true,
      challengeEnabled: json['challengeEnabled'] as bool? ?? true,
      sleepyMeProtection: json['sleepyMeProtection'] as bool? ?? true,
      proofOfAwake: json['proofOfAwake'] as bool? ?? false,
      weekdays: rawDays?.map((item) => item as int).toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      ringtonePath: json['ringtonePath'] as String?,
      ringtoneName:
          json['ringtoneName'] as String? ?? 'نغمة المنبّه الافتراضية',
    );
  }

  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    final activeDays = weekdays.isEmpty
        ? const <int>[1, 2, 3, 4, 5, 6, 7]
        : weekdays;
    for (var add = 0; add < 8; add++) {
      final candidateDay = now.add(Duration(days: add));
      if (!activeDays.contains(candidateDay.weekday)) continue;
      final candidate = DateTime(
        candidateDay.year,
        candidateDay.month,
        candidateDay.day,
        hour,
        minute,
      );
      if (candidate.isAfter(now)) return candidate;
    }
    return DateTime(now.year, now.month, now.day, hour, minute)
        .add(const Duration(days: 7));
  }

  int get wakeStrength {
    var score = 35;
    if (challengeEnabled) score += 25;
    if (sleepyMeProtection) score += 20;
    if (proofOfAwake) score += 20;
    return score.clamp(0, 100);
  }
}
