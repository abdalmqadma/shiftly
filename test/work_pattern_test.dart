import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/models/work_pattern.dart';
import 'package:shiftly/services/alarm_service.dart';
import 'package:shiftly/services/pattern_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('custom alarms and per-shift fixed offsets survive storage', () async {
    final original = WorkPattern(
      cycleStart: DateTime(2026, 11, 1, 7),
      dutyMinutes: 72 * 60,
      offMinutes: 24 * 60,
      alarmBeforeMinutes: 30,
      shifts: const [
        WorkShift(
          name: 'Shift 1',
          startOffsetMinutes: 60,
          endOffsetMinutes: 600,
          useCustomAlarms: true,
          customAlarmOffsetsMinutes: [90, 240, 480],
        ),
        WorkShift(
          name: 'Shift 2',
          startOffsetMinutes: 720,
          endOffsetMinutes: 1200,
          fixedAlarmBeforeMinutes: 45,
        ),
      ],
    );

    await PatternStorage.save(original);
    final restored = await PatternStorage.load();

    expect(restored, isNotNull);
    expect(restored!.cycleStart, original.cycleStart);
    expect(restored.shifts[0].useCustomAlarms, isTrue);
    expect(restored.shifts[0].customAlarmOffsetsMinutes, [90, 240, 480]);
    expect(restored.shifts[1].fixedAlarmBeforeMinutes, 45);
    expect(restored.shifts[1].fixedAlarmEnabled, isTrue);
    expect(restored.alarmBeforeMinutes, 30);
  });

  test('disabled fixed reminders and empty custom alarm lists survive storage', () async {
    final original = WorkPattern(
      cycleStart: DateTime(2026, 11, 1, 7),
      dutyMinutes: 72 * 60,
      offMinutes: 24 * 60,
      alarmBeforeMinutes: 30,
      shifts: const [
        WorkShift(
          name: 'No reminder',
          startOffsetMinutes: 60,
          endOffsetMinutes: 600,
          fixedAlarmEnabled: false,
        ),
        WorkShift(
          name: 'No custom reminders',
          startOffsetMinutes: 720,
          endOffsetMinutes: 1200,
          useCustomAlarms: true,
          customAlarmOffsetsMinutes: [],
        ),
      ],
    );
    await PatternStorage.save(original);
    final restored = await PatternStorage.load();
    expect(restored!.shifts[0].fixedAlarmEnabled, isFalse);
    expect(restored.shifts[1].useCustomAlarms, isTrue);
    expect(restored.shifts[1].customAlarmOffsetsMinutes, isEmpty);
  });

  test('pattern alarm IDs stay in a dedicated range and do not repeat after 10 days', () {
    final first = DateTime(2026, 11, 1, 3, 30);
    final later = first.add(const Duration(days: 10));

    final firstId = AlarmService.patternAlarmIdFor(first);
    final laterId = AlarmService.patternAlarmIdFor(later);

    expect(AlarmService.isPatternAlarmId(firstId), isTrue);
    expect(AlarmService.isPatternAlarmId(laterId), isTrue);
    expect(firstId, isNot(laterId));
    expect(firstId, greaterThanOrEqualTo(2050000000));
    expect(laterId, lessThanOrEqualTo(2147483646));
  });

  test('legacy work patterns load with no per-shift alarm overrides', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('work_pattern_v1', '''
      {
        "cycleStart": "2026-11-01T07:00:00.000",
        "dutyMinutes": 4320,
        "offMinutes": 1440,
        "alarmBeforeMinutes": 30,
        "shifts": [
          {"name": "Old shift", "start": 60, "end": 600}
        ]
      }
    ''');

    final restored = await PatternStorage.load();

    expect(restored, isNotNull);
    expect(restored!.shifts.single.useCustomAlarms, isFalse);
    expect(restored.shifts.single.customAlarmOffsetsMinutes, isEmpty);
    expect(restored.shifts.single.fixedAlarmBeforeMinutes, isNull);
  });
}
