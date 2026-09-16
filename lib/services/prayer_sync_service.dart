import 'dart:convert';

import '../models/prayer_alarm_rule.dart';
import 'alarm_service.dart';
import 'prayer_alarm_service.dart';
import 'prayer_alarm_storage.dart';

class PrayerSyncService {
  const PrayerSyncService._();

  static const allowedPrayers = <String>{
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  };

  static Future<List<PrayerAlarmRule>> apply(Uri uri) async {
    final latitude = double.tryParse(uri.queryParameters['lat'] ?? '');
    final longitude = double.tryParse(uri.queryParameters['lon'] ?? '');
    final method = int.tryParse(uri.queryParameters['method'] ?? '');
    final school = int.tryParse(uri.queryParameters['school'] ?? '') ?? 0;
    final tune = uri.queryParameters['tune'];
    final rawRules = uri.queryParameters['rules'];

    if (latitude == null ||
        longitude == null ||
        method == null ||
        rawRules == null ||
        rawRules.isEmpty) {
      throw const FormatException('Missing prayer sync parameters');
    }

    final decoded = jsonDecode(rawRules);
    if (decoded is! List) {
      throw const FormatException('Invalid prayer sync payload');
    }

    final existing = await PrayerAlarmStorage.load();
    final existingByPrayer = {
      for (final rule in existing) rule.prayer: rule,
    };

    final incoming = <PrayerAlarmRule>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final prayer = map['prayer'] as String?;
      if (prayer == null || !allowedPrayers.contains(prayer)) continue;

      final previous = existingByPrayer[prayer];
      incoming.add(
        PrayerAlarmRule(
          prayer: prayer,
          latitude: latitude,
          longitude: longitude,
          method: method,
          school: school,
          tune: tune,
          offsetMinutes: (map['offsetMinutes'] as num?)?.toInt() ?? 0,
          challengeEnabled: map['challengeEnabled'] as bool? ?? false,
          enabled: map['enabled'] as bool? ?? false,
          ringtonePath: previous?.ringtonePath,
          ringtoneName: previous?.ringtoneName,
        ),
      );
    }

    if (incoming.isEmpty) {
      throw const FormatException('No valid prayer rules in payload');
    }

    final preserved = existing
        .where((rule) => !allowedPrayers.contains(rule.prayer))
        .toList();
    final updated = [...preserved, ...incoming];
    await PrayerAlarmStorage.save(updated);

    for (final rule in incoming) {
      if (rule.enabled) {
        await PrayerAlarmService.scheduleNext(rule);
      } else {
        await AlarmService.stopWakeAlarm(rule.alarmId);
      }
    }

    return incoming;
  }
}
