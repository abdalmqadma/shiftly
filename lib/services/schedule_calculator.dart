import '../models/work_pattern.dart';

enum ScheduleState { work, rest, off }

class ScheduleMoment {
  const ScheduleMoment(this.state, this.title);
  final ScheduleState state;
  final String title;
}

class ScheduleCalculator {
  const ScheduleCalculator(this.pattern);
  final WorkPattern pattern;

  int cycleOffset(DateTime date) {
    final difference = date.difference(pattern.cycleStart).inMinutes;
    return ((difference % pattern.cycleMinutes) + pattern.cycleMinutes) %
        pattern.cycleMinutes;
  }

  ScheduleMoment stateAt(DateTime date) {
    final offset = cycleOffset(date);
    for (final shift in pattern.shifts) {
      if (offset >= shift.startOffsetMinutes &&
          offset < shift.endOffsetMinutes) {
        return ScheduleMoment(ScheduleState.work, shift.name);
      }
    }
    if (offset < pattern.dutyMinutes) {
      return const ScheduleMoment(ScheduleState.rest, 'راحة داخل الدوام');
    }
    return const ScheduleMoment(ScheduleState.off, 'إجازة');
  }

  DateTime nextShiftStart(DateTime from) {
    final cycle = pattern.cycleMinutes;
    final elapsed = from.difference(pattern.cycleStart).inMinutes;
    final cycleIndex = elapsed ~/ cycle;

    for (var index = cycleIndex - 1; index < cycleIndex + 500; index++) {
      final base = pattern.cycleStart.add(Duration(minutes: index * cycle));
      for (final shift in pattern.shifts) {
        final start =
            base.add(Duration(minutes: shift.startOffsetMinutes));
        if (start.isAfter(from)) return start;
      }
    }
    return from;
  }
}
