class WorkShift {
  const WorkShift({
    required this.name,
    required this.startOffsetMinutes,
    required this.endOffsetMinutes,
    this.useCustomAlarms = false,
    this.customAlarmOffsetsMinutes = const [],
  });

  final String name;
  final int startOffsetMinutes;
  final int endOffsetMinutes;

  /// When true, this shift uses its own alarm times instead of the
  /// pattern-wide "minutes before shift" reminder.
  final bool useCustomAlarms;

  /// Alarm times as minute offsets from the beginning of the work cycle.
  /// They are repeated whenever this shift occurs in a later cycle.
  final List<int> customAlarmOffsetsMinutes;
}

class WorkPattern {
  const WorkPattern({
    required this.cycleStart,
    required this.dutyMinutes,
    required this.offMinutes,
    required this.alarmBeforeMinutes,
    required this.shifts,
    this.ringtonePath,
    this.ringtoneName = 'نغمة المنبّه الافتراضية',
  });

  final DateTime cycleStart;
  final int dutyMinutes;
  final int offMinutes;
  final int alarmBeforeMinutes;
  final List<WorkShift> shifts;
  final String? ringtonePath;
  final String ringtoneName;

  int get cycleMinutes => dutyMinutes + offMinutes;
}
