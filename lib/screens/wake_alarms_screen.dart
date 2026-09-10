import 'package:flutter/material.dart';
import '../models/wake_alarm.dart';
import '../models/work_pattern.dart';
import '../services/alarm_service.dart';

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

  static const violet = Color(0xFF6D4AFF);

  @override
  Widget build(BuildContext context) {
    final shifts = _todayShiftAlarms();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            const Text('منبّهاتك',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('منبّهاتك اليدوية + تنبيهات شفتات اليوم في مكان واحد.',
                style: TextStyle(color: Colors.grey.shade600)),
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
        backgroundColor: violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('منبّه جديد',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) => Row(children: [
        Icon(icon, size: 20, color: violet),
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

  Widget _shiftAlarmCard(BuildContext context, _TodayShiftAlarm item) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE4DCFF)),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge_outlined, color: violet),
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
                Text('بداية الشفت ${_formatTime(item.shiftStart)} • يختفي بعد الرنين',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل تنبيه اليوم',
            onPressed: () => _editShiftAlarm(context, item),
            icon: const Icon(Icons.edit_alarm_rounded, color: violet),
          ),
        ]),
      );

  Widget _emptyState(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: violet.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bedtime_outlined, color: violet, size: 36),
          ),
          const SizedBox(height: 18),
          const Text('أضف أول منبّه',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('اختَر الوقت، أيام الأسبوع، وتخصيصات الاستيقاظ من شاشة واحدة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
        ]),
      );

  Widget _alarmCard(BuildContext context, WakeAlarm alarm) => Dismissible(
        key: ValueKey(alarm.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatClock(alarm.hour, alarm.minute),
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          color: alarm.enabled ? Colors.black87 : Colors.black38,
                        )),
                    const SizedBox(height: 4),
                    Text(alarm.label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    Text(_daysLabel(alarm.weekdays),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 7, runSpacing: 7, children: [
                      if (alarm.challengeEnabled)
                        _chip(Icons.calculate_outlined, 'تحدي'),
                      if (alarm.sleepyMeProtection)
                        _chip(Icons.lock_outline_rounded, 'Sleepy-Me'),
                      if (alarm.proofOfAwake)
                        _chip(Icons.verified_outlined, 'إثبات الاستيقاظ'),
                      _chip(Icons.bolt_rounded, '${alarm.wakeStrength}%'),
                    ]),
                  ],
                ),
              ),
              Switch(
                value: alarm.enabled,
                activeThumbColor: violet,
                onChanged: (value) => onToggle(alarm, value),
              ),
            ]),
          ),
        ),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: violet),
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
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف')),
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
    final result = await showModalBottomSheet<WakeAlarm>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AlarmEditor(alarm: alarm),
    );
    if (result == null) return;
    if (alarm == null) {
      await onAdd(result);
    } else {
      await onUpdate(result);
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
    const names = {1: 'الإثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد'};
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

class _AlarmEditor extends StatefulWidget {
  const _AlarmEditor({this.alarm});
  final WakeAlarm? alarm;

  @override
  State<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<_AlarmEditor> {
  static const violet = Color(0xFF6D4AFF);
  late TimeOfDay time;
  late TextEditingController labelController;
  late Set<int> days;
  late bool challenge;
  late bool sleepyMe;
  late bool proofOfAwake;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    time = alarm == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: alarm.hour, minute: alarm.minute);
    labelController = TextEditingController(text: alarm?.label ?? 'استيقاظ');
    days = Set<int>.from(alarm?.weekdays ?? const [1, 2, 3, 4, 5, 6, 7]);
    challenge = alarm?.challengeEnabled ?? true;
    sleepyMe = alarm?.sleepyMeProtection ?? true;
    proofOfAwake = alarm?.proofOfAwake ?? false;
  }

  @override
  void dispose() {
    labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(widget.alarm == null ? 'منبّه جديد' : 'تعديل المنبّه',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(children: [
                  const Text('وقت المنبّه'),
                  const SizedBox(height: 6),
                  Text(time.format(context),
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: violet)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'اسم المنبّه',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('أيام التكرار', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: const [
                (7, 'أحد'), (1, 'إثن'), (2, 'ثلا'), (3, 'أرب'),
                (4, 'خمي'), (5, 'جمع'), (6, 'سبت'),
              ].map((entry) {
                final selected = days.contains(entry.$1);
                return FilterChip(
                  label: Text(entry.$2),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      days.add(entry.$1);
                    } else if (days.length > 1) {
                      days.remove(entry.$1);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('تخصيصات Shiftly', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تحدي الاستيقاظ'),
              subtitle: const Text('حل تحدي قبل إيقاف المنبّه'),
              value: challenge,
              onChanged: (value) => setState(() => challenge = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sleepy-Me Protection'),
              subtitle: const Text('حماية من إغلاق المنبّه وأنت نص نايم'),
              value: sleepyMe,
              onChanged: (value) => setState(() => sleepyMe = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('إثبات الاستيقاظ'),
              subtitle: const Text('تأكيد إضافي بعد الاستيقاظ'),
              value: proofOfAwake,
              onChanged: (value) => setState(() => proofOfAwake = value),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.alarm_on_rounded),
              label: Text(widget.alarm == null ? 'إضافة المنبّه' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: time);
    if (selected != null) setState(() => time = selected);
  }

  void _save() {
    final label = labelController.text.trim();
    if (label.isEmpty) return;
    final old = widget.alarm;
    Navigator.pop(
      context,
      WakeAlarm(
        id: old?.id ?? 0,
        hour: time.hour,
        minute: time.minute,
        label: label,
        enabled: old?.enabled ?? true,
        weekdays: days.toList()..sort(),
        challengeEnabled: challenge,
        sleepyMeProtection: sleepyMe,
        proofOfAwake: proofOfAwake,
        ringtonePath: old?.ringtonePath,
      ),
    );
  }
}
