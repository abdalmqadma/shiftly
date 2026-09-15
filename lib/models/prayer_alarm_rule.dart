class PrayerAlarmRule {
  const PrayerAlarmRule({
    required this.prayer,
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.school,
    required this.offsetMinutes,
    required this.challengeEnabled,
    required this.enabled,
    this.tune,
    this.ringtonePath,
    this.ringtoneName,
  });

  final String prayer;
  final double latitude;
  final double longitude;
  final int method;
  final int school;
  final String? tune;
  final int offsetMinutes;
  final bool challengeEnabled;
  final bool enabled;
  final String? ringtonePath;
  final String? ringtoneName;

  int get alarmId => 920000000 + const {
        'Fajr': 1,
        'Sunrise': 2,
        'Dhuhr': 3,
        'Asr': 4,
        'Maghrib': 5,
        'Isha': 6,
      }[prayer]!.toInt();

  String get arabicName => const {
        'Fajr': 'الفجر',
        'Sunrise': 'الشروق',
        'Dhuhr': 'الظهر',
        'Asr': 'العصر',
        'Maghrib': 'المغرب',
        'Isha': 'العشاء',
      }[prayer] ?? prayer;

  PrayerAlarmRule copyWith({
    int? offsetMinutes,
    bool? challengeEnabled,
    bool? enabled,
    String? ringtonePath,
    String? ringtoneName,
  }) =>
      PrayerAlarmRule(
        prayer: prayer,
        latitude: latitude,
        longitude: longitude,
        method: method,
        school: school,
        tune: tune,
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
        challengeEnabled: challengeEnabled ?? this.challengeEnabled,
        enabled: enabled ?? this.enabled,
        ringtonePath: ringtonePath ?? this.ringtonePath,
        ringtoneName: ringtoneName ?? this.ringtoneName,
      );

  Map<String, dynamic> toJson() => {
        'prayer': prayer,
        'latitude': latitude,
        'longitude': longitude,
        'method': method,
        'school': school,
        'tune': tune,
        'offsetMinutes': offsetMinutes,
        'challengeEnabled': challengeEnabled,
        'enabled': enabled,
        'ringtonePath': ringtonePath,
        'ringtoneName': ringtoneName,
      };

  factory PrayerAlarmRule.fromJson(Map<String, dynamic> json) => PrayerAlarmRule(
        prayer: json['prayer'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        method: (json['method'] as num).toInt(),
        school: (json['school'] as num).toInt(),
        tune: json['tune'] as String?,
        offsetMinutes: (json['offsetMinutes'] as num?)?.toInt() ?? 0,
        challengeEnabled: json['challengeEnabled'] as bool? ?? true,
        enabled: json['enabled'] as bool? ?? true,
        ringtonePath: json['ringtonePath'] as String?,
        ringtoneName: json['ringtoneName'] as String?,
      );
}
