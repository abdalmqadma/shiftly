import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/wake_alarm.dart';
import '../models/work_pattern.dart';
import '../services/alarm_service.dart';
import 'alarm_editor_screen.dart';

class WakeAlarmsScreen extends StatelessWidget {
  const WakeAlarmsScreen({
    super.key,
    required this.alarms,
    required this.pattern,
    required this.onAdd,
    required this.onUpdate,
    required this.onToggle,
    required this.onDelete,
    required this.onEditTodayShiftAlarm,
  });

  final List<WakeAlarm> alarms;
  final WorkPattern? pattern;
  final Future<void> Function(WakeAlarm alarm) onAdd;
  final Future<void> Function(WakeAlarm alarm) onUpdate;
  final Future<void> Function(WakeAlarm alarm, bool enabled) onToggle;
  final Future<void> Function(WakeAlarm alarm) onDelete;
  final Future<void> Function({
    required int alarmId,
    required String title,
    required DateTime oldTime,
    required DateTime newTime,
  }) onEditTodayShiftAlarm;

  @override
  Widget build(BuildContext context) {
    final shifts = _todayShiftAlarms();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            const Text('منبّهاتك',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'منبّهاتك اليدوية + تنبيهات شفتات اليوم في مكان واحد.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (shifts.isNotEmpty) ...[
              const SizedBox(height: 22),
              _sectionTitle('شفتات اليوم', Icons.work_history_rounded),
              const SizedBox(height: 10),
              ...shifts.map((item) => _shiftAlarmCard(context, item)),
            ],
            const SizedBox(height: 22),
            _sectionTitle('المنبّهات اليدوية', Icons.alarm_rounded),
            const SizedBox(height: 10),
            if (alarms.isEmpty)
              _emptyState(context)
            else
              ...alarms.map((alarm) => _alarmCard(context, alarm)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('منبّه جديد',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) => Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ]);

  List<_TodayShiftAlarm> _todayShiftAlarms() {
    final p = pattern;
    if (p == null) return const [];
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final elapsed = startOfDay.difference(p.cycleStart).inMinutes;
    final baseIndex = elapsed ~/ p.cycleMinutes;
    final result = <_TodayShiftAlarm>[];

    for (var index = baseIndex - 1; index <= baseIndex + 1; index++) {
      final base = p.cycleStart.add(Duration(minutes: index * p.cycleMinutes));
      for (final shift in p.shifts) {
        final shiftStart = base.add(Duration(minutes: shift.startOffsetMinutes));
        if (shiftStart.isBefore(startOfDay) || !shiftStart.isBefore(endOfDay)) {
          continue;
        }
        final alarmTime =
            shiftStart.subtract(Duration(minutes: p.alarmBeforeMinutes));
        if (!alarmTime.isAfter(now)) continue;
        result.add(_TodayShiftAlarm(
          id: AlarmService.patternAlarmIdFor(alarmTime),
          title: shift.name,
          shiftStart: shiftStart,
          alarmTime: alarmTime,
        ));
      }
    }
    result.sort((a, b) => a.alarmTime.compareTo(b.alarmTime));
    return result;
  }

  Widget _shiftAlarmCard(BuildContext context, _TodayShiftAlarm item) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.badge_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatTime(item.alarmTime),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900)),
              Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'بداية الشفت ${_formatTime(item.shiftStart)} • يختفي بعد الرنين',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'تعديل تنبيه اليوم',
          onPressed: () => _editShiftAlarm(context, item),
          icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
        ),
      ]),
    );
  }

  Widget _emptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bedtime_outlined,
              color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 18),
        const Text('أضف أول منبّه',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'افتح محرر Shiftly الكامل واضبط الوقت والنغمة والتكرار والتحديات.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ]),
    );
  }

  Widget _alarmCard(BuildContext context, WakeAlarm alarm) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      confirmDismiss: (_) => _confirmDelete(context, alarm),
      onDismissed: (_) => onDelete(alarm),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openEditor(context, alarm: alarm),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatClock(alarm.hour, alarm.minute),
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: alarm.enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: .35),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(alarm.label,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  Row(children: [
                    const Icon(Icons.music_note_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        alarm.ringtoneName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 7),
                  Text(_daysLabel(alarm.weekdays),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 7, runSpacing: 7, children: [
                    if (alarm.challengeEnabled)
                      _chip(context, Icons.calculate_outlined, 'تحدي'),
                    if (alarm.sleepyMeProtection)
                      _chip(context, Icons.lock_outline_rounded, 'Sleepy-Me'),
                    if (alarm.proofOfAwake)
                      _chip(context, Icons.verified_outlined, 'إثبات الاستيقاظ'),
                    _chip(context, Icons.bolt_rounded, '${alarm.wakeStrength}%'),
                  ]),
                ],
              ),
            ),
            Switch(
              value: alarm.enabled,
              activeThumbColor: AppColors.primary,
              onChanged: (value) => onToggle(alarm, value),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );

  Future<bool> _confirmDelete(BuildContext context, WakeAlarm alarm) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('حذف المنبّه؟'),
          content: Text(alarm.label),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _editShiftAlarm(
      BuildContext context, _TodayShiftAlarm item) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(item.alarmTime),
      helpText: 'تعديل تنبيه هذا الشفت فقط',
    );
    if (picked == null) return;
    final newTime = DateTime(
      item.alarmTime.year,
      item.alarmTime.month,
      item.alarmTime.day,
      picked.hour,
      picked.minute,
    );
    await onEditTodayShiftAlarm(
      alarmId: item.id,
      title: item.title,
      oldTime: item.alarmTime,
      newTime: newTime,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل تنبيه شفت اليوم')),
      );
    }
  }

  Future<void> _openEditor(BuildContext context, {WakeAlarm? alarm}) async {
    final result = await Navigator.of(context).push<AlarmEditorResult>(
      MaterialPageRoute<AlarmEditorResult>(
        fullscreenDialog: true,
        builder: (_) => AlarmEditorScreen(alarm: alarm),
      ),
    );
    if (result == null) return;
    if (result.deleteRequested && alarm != null) {
      await onDelete(alarm);
      return;
    }
    final saved = result.alarm;
    if (saved == null) return;
    if (alarm == null) {
      await onAdd(saved);
    } else {
      await onUpdate(saved);
    }
  }

  String _formatTime(DateTime value) => _formatClock(value.hour, value.minute);

  String _formatClock(int hour24, int minute) {
    final suffix = hour24 < 12 ? 'ص' : 'م';
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String _daysLabel(List<int> days) {
    if (days.length == 7) return 'كل يوم';
    const names = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد'
    };
    return days.map((day) => names[day]).whereType<String>().join('، ');
  }
}

class _TodayShiftAlarm {
  const _TodayShiftAlarm({
    required this.id,
    required this.title,
    required this.shiftStart,
    required this.alarmTime,
  });

  final int id;
  final String title;
  final DateTime shiftStart;
  final DateTime alarmTime;
}
