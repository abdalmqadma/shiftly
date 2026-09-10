import 'package:flutter/material.dart';
import '../models/wake_alarm.dart';

class WakeAlarmsScreen extends StatelessWidget {
  const WakeAlarmsScreen({
    super.key,
    required this.alarms,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  final List<WakeAlarm> alarms;
  final Future<void> Function(TimeOfDay time, String label) onAdd;
  final Future<void> Function(WakeAlarm alarm, bool enabled) onToggle;
  final Future<void> Function(WakeAlarm alarm) onDelete;

  static const violet = Color(0xFF6D4AFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            const Text('منبّهاتك',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Shiftly ما بس يرن — بخليك تثبت إنك صحيت.',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 22),
            if (alarms.isEmpty)
              _emptyState(context)
            else
              ...alarms.map((alarm) => _alarmCard(context, alarm)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAlarm(context),
        backgroundColor: violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('منبّه جديد',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

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
          Text('كل منبّه جديد يبدأ بتحدي استيقاظ إجباري.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
        ]),
      );

  Widget _alarmCard(BuildContext context, WakeAlarm alarm) {
    final suffix = alarm.hour < 12 ? 'ص' : 'م';
    final hour = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
    final time = '$hour:${alarm.minute.toString().padLeft(2, '0')} $suffix';

    return Dismissible(
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (_) => onDelete(alarm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: alarm.enabled ? Colors.black87 : Colors.black38,
                    )),
                const SizedBox(height: 4),
                Text(alarm.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip(Icons.calculate_outlined, '3 مسائل'),
                  _chip(Icons.lock_outline_rounded, 'حماية من الإغلاق'),
                  _chip(Icons.bolt_rounded, '${alarm.wakeStrength}% قوة'),
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
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  Future<void> _showAddAlarm(BuildContext context) async {
    final now = TimeOfDay.now();
    final selected = await showTimePicker(context: context, initialTime: now);
    if (selected == null || !context.mounted) return;

    final controller = TextEditingController(text: 'استيقاظ');
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اسم المنبّه'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'مثال: الجامعة'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('حفظ')),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.trim().isEmpty) return;
    await onAdd(selected, label.trim());
  }
}
