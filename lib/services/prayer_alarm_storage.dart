import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_alarm_rule.dart';

class PrayerAlarmStorage {
  const PrayerAlarmStorage._();

  static const _key = 'prayer_alarm_rules_v1';

  static Future<List<PrayerAlarmRule>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PrayerAlarmRule.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<PrayerAlarmRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(rules.map((rule) => rule.toJson()).toList()),
    );
  }

  static Future<void> upsert(PrayerAlarmRule rule) async {
    final rules = await load();
    final updated = [
      ...rules.where((item) => item.prayer != rule.prayer),
      rule,
    ];
    await save(updated);
  }
}
