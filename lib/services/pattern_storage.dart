import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_pattern.dart';

class PatternStorage {
  const PatternStorage._();
  static const _key = 'work_pattern_v1';

  static Future<void> save(WorkPattern pattern) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode({
        'cycleStart': pattern.cycleStart.toIso8601String(),
        'dutyMinutes': pattern.dutyMinutes,
        'offMinutes': pattern.offMinutes,
        'alarmBeforeMinutes': pattern.alarmBeforeMinutes,
        'ringtonePath': pattern.ringtonePath,
        'ringtoneName': pattern.ringtoneName,
        'shifts': pattern.shifts
            .map((shift) => {
                  'name': shift.name,
                  'start': shift.startOffsetMinutes,
                  'end': shift.endOffsetMinutes,
                })
            .toList(),
      }),
    );
  }

  static Future<WorkPattern?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final source = preferences.getString(_key);
    if (source == null) return null;

    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final shifts = (json['shifts'] as List<dynamic>)
          .map((item) {
            final value = item as Map<String, dynamic>;
            return WorkShift(
              name: value['name'] as String,
              startOffsetMinutes: value['start'] as int,
              endOffsetMinutes: value['end'] as int,
            );
          })
          .toList();

      return WorkPattern(
        cycleStart: DateTime.parse(json['cycleStart'] as String),
        dutyMinutes: json['dutyMinutes'] as int,
        offMinutes: json['offMinutes'] as int,
        alarmBeforeMinutes: json['alarmBeforeMinutes'] as int,
        shifts: shifts,
        ringtonePath: json['ringtonePath'] as String?,
        ringtoneName:
            json['ringtoneName'] as String? ?? 'نغمة المنبّه الافتراضية',
      );
    } catch (_) {
      return null;
    }
  }
}
