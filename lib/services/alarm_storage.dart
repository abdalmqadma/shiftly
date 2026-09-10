import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wake_alarm.dart';

class AlarmStorage {
  const AlarmStorage._();
  static const _key = 'wake_alarms_v1';

  static Future<List<WakeAlarm>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final source = preferences.getString(_key);
      if (source == null) return const [];
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .map((item) => WakeAlarm.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<WakeAlarm> alarms) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(alarms.map((alarm) => alarm.toJson()).toList()),
    );
  }
}
