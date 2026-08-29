class WorkShift {
  const WorkShift({
    required this.name,
    required this.startOffsetMinutes,
    required this.endOffsetMinutes,
  });

  final String name;
  final int startOffsetMinutes;
  final int endOffsetMinutes;
}

class WorkPattern {
  const WorkPattern({
    required this.cycleStart,
    required this.dutyMinutes,
    required this.offMinutes,
    required this.alarmBeforeMinutes,
    required this.shifts,
  });

  final DateTime cycleStart;
  final int dutyMinutes;
  final int offMinutes;
  final int alarmBeforeMinutes;
  final List<WorkShift> shifts;

  int get cycleMinutes => dutyMinutes + offMinutes;
}
