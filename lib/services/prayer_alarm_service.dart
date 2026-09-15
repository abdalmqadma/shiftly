import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prayer_alarm_rule.dart';
import 'alarm_service.dart';
import 'prayer_alarm_storage.dart';

class PrayerAlarmService {
  const PrayerAlarmService._();

  static const _timeout = Duration(seconds: 20);

  static bool isPrayerAlarmId(int id) => id >= 920000001 && id <= 920000006;

  static Future<void> replenishAll() async {
    final rules = await PrayerAlarmStorage.load();
    for (final rule in rules.where((item) => item.enabled)) {
      await scheduleNext(rule);
    }
  }

  static Future<void> scheduleNext(PrayerAlarmRule rule) async {
    await AlarmService.stopWakeAlarm(rule.alarmId);
    if (!rule.enabled) return;

    final next = await _nextOccurrence(rule);
    await AlarmService.schedulePrayerAlarm(
      id: rule.alarmId,
      dateTime: next,
      title: 'صلاة ${rule.arabicName}',
      audioPath: rule.ringtonePath,
    );
  }

  static Future<DateTime> _nextOccurrence(PrayerAlarmRule rule) async {
    final now = DateTime.now();
    final months = <DateTime>[
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    ];

    for (final month in months) {
      final days = await _fetchMonth(rule, month);
      for (final day in days) {
        final date = DateTime.parse(day['date']!);
        final rawTime = day[rule.prayer];
        if (rawTime == null || rawTime.isEmpty) continue;
        final parts = rawTime.split(':');
        if (parts.length != 2) continue;
        final prayerTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final alarmTime = prayerTime.add(Duration(minutes: rule.offsetMinutes));
        if (alarmTime.isAfter(now.add(const Duration(seconds: 5)))) {
          return alarmTime;
        }
      }
    }

    throw StateError('No upcoming prayer time found');
  }

  static Future<List<Map<String, String>>> _fetchMonth(
    PrayerAlarmRule rule,
    DateTime month,
  ) async {
    final query = <String, String>{
      'latitude': rule.latitude.toString(),
      'longitude': rule.longitude.toString(),
      'method': rule.method.toString(),
      'school': rule.school.toString(),
    };
    if (rule.tune != null && rule.tune!.isNotEmpty) {
      query['tune'] = rule.tune!;
    }

    final uri = Uri.https(
      'api.aladhan.com',
      '/v1/calendar/${month.year}/${month.month}',
      query,
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw StateError('Prayer API returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['code'] != 200 || decoded['data'] is! List) {
      throw const FormatException('Invalid prayer API response');
    }

    String cleanTime(dynamic value) {
      final match = RegExp(r'\b([01]?\d|2[0-3]):[0-5]\d\b')
          .firstMatch((value ?? '').toString());
      return match?.group(0)?.padLeft(5, '0') ?? '';
    }

    final result = <Map<String, String>>[];
    for (final raw in decoded['data'] as List) {
      if (raw is! Map) continue;
      final timings = Map<String, dynamic>.from(raw['timings'] as Map? ?? {});
      final dateMap = Map<String, dynamic>.from(raw['date'] as Map? ?? {});
      final gregorian =
          Map<String, dynamic>.from(dateMap['gregorian'] as Map? ?? {});
      final parts = (gregorian['date'] ?? '').toString().split('-');
      if (parts.length != 3) continue;
      result.add({
        'date': '${parts[2]}-${parts[1]}-${parts[0]}',
        'Fajr': cleanTime(timings['Fajr']),
        'Sunrise': cleanTime(timings['Sunrise']),
        'Dhuhr': cleanTime(timings['Dhuhr']),
        'Asr': cleanTime(timings['Asr']),
        'Maghrib': cleanTime(timings['Maghrib']),
        'Isha': cleanTime(timings['Isha']),
      });
    }
    return result;
  }
}
