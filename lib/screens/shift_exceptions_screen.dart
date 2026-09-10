import 'package:flutter/material.dart';
import '../models/shift_exception.dart';

class ShiftExceptionsScreen extends StatelessWidget {
  const ShiftExceptionsScreen({
    super.key,
    required this.exceptions,
    required this.defaultAlarmBeforeMinutes,
    required this.onAdd,
    required this.onDelete,
  });

  final List<ShiftException> exceptions;
  final int defaultAlarmBeforeMinutes;
  final Future<void> Function({
    required String title,
    required DateTime start,
    required DateTime end,
    required int alarmBeforeMinutes,
  }) onAdd;
  final Future<void> Function(ShiftException exception) onDelete;

  static const violet = Color(0xFF6D4AFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طوارئ واستثناءات الشفتات')),
      body: exceptions.isEmpty
          ? _emptyState(context)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _introCard(),
                const SizedBox(height: 16),
                ...exceptions.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _exceptionCard(context, item),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('إضافة طارئ'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _introCard(),
          const SizedBox(height: 36),
          const Icon(Icons.event_available_outlined, size: 72, color: violet),
          const SizedBox(height: 16),
          const Text(
            'ما عندك استثناءات حالياً',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'إذا غبت، غطّيت مكان شخص، أو عندك شفت إضافي بيوم معيّن، أضفه هون بدون تغيير دورة المناوبة الأساسية.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة استثناء ليوم معيّن'),
          ),
        ],
      );

  Widget _introCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emergency_outlined, color: violet),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'استثناء بدون تخريب الجدول',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الاستثناء مستقل عن دورة الشفتات، وله تنبيه خاص فيه.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _exceptionCard(BuildContext context, ShiftException item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEDE8FF),
                  child: Icon(Icons.work_history_rounded, color: violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(_dateLabel(item.start),
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => _confirmDelete(context, item),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.schedule_rounded,
                    '${_timeLabel(item.start)} - ${_timeLabel(item.end)}'),
                _chip(Icons.notifications_active_outlined,
                    'تنبيه قبل ${item.alarmBeforeMinutes} دقيقة'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: violet),
            const SizedBox(width: 6),
            Text(text,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Future<void> _showAddDialog(BuildContext context) async {
    final result = await showDialog<_ExceptionDraft>(
      context: context,
      builder: (_) => _AddShiftExceptionDialog(
        defaultAlarmBeforeMinutes: defaultAlarmBeforeMinutes,
      ),
    );
    if (result == null) return;
    await onAdd(
      title: result.title,
      start: result.start,
      end: result.end,
      alarmBeforeMinutes: result.alarmBeforeMinutes,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ShiftException exception) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الاستثناء؟'),
        content: Text('سيتم حذف "${exception.title}" وإلغاء تنبيهه.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed == true) await onDelete(exception);
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _timeLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'م' : 'ص'}';
  }
}

class _ExceptionDraft {
  const _ExceptionDraft({
    required this.title,
    required this.start,
    required this.end,
    required this.alarmBeforeMinutes,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final int alarmBeforeMinutes;
}

class _AddShiftExceptionDialog extends StatefulWidget {
  const _AddShiftExceptionDialog({required this.defaultAlarmBeforeMinutes});

  final int defaultAlarmBeforeMinutes;

  @override
  State<_AddShiftExceptionDialog> createState() =>
      _AddShiftExceptionDialogState();
}

class _AddShiftExceptionDialogState extends State<_AddShiftExceptionDialog> {
  late final TextEditingController titleController;
  late final TextEditingController alarmController;
  DateTime date = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);
  String? error;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: 'شفت طارئ');
    alarmController =
        TextEditingController(text: widget.defaultAlarmBeforeMinutes.toString());
  }

  @override
  void dispose() {
    titleController.dispose();
    alarmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة استثناء'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'السبب أو اسم الشفت',
                hintText: 'مثلاً: تغطية مكان أحمد',
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('التاريخ'),
              subtitle: Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
              onTap: _pickDate,
            ),
            Row(
              children: [
                Expanded(child: _timeTile('البداية', startTime, true)),
                const SizedBox(width: 8),
                Expanded(child: _timeTile('النهاية', endTime, false)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: alarmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'التنبيه قبل الشفت بالدقائق',
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: _save, child: const Text('حفظ وتنبيه')),
      ],
    );
  }

  Widget _timeTile(String label, TimeOfDay value, bool start) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pickTime(start),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _pickTime(bool isStart) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        startTime = selected;
      } else {
        endTime = selected;
      }
    });
  }

  void _save() {
    final title = titleController.text.trim();
    final before = int.tryParse(alarmController.text.trim());
    final start = DateTime(
        date.year, date.month, date.day, startTime.hour, startTime.minute);
    var end =
        DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));

    if (title.isEmpty) {
      setState(() => error = 'اكتب سبب أو اسم للشفت الطارئ.');
      return;
    }
    if (before == null || before < 0 || before > 1440) {
      setState(() => error = 'وقت التنبيه لازم يكون بين 0 و1440 دقيقة.');
      return;
    }
    if (!start.isAfter(DateTime.now())) {
      setState(() => error = 'اختَر وقت بداية قادم.');
      return;
    }

    Navigator.pop(
      context,
      _ExceptionDraft(
        title: title,
        start: start,
        end: end,
        alarmBeforeMinutes: before,
      ),
    );
  }
}
