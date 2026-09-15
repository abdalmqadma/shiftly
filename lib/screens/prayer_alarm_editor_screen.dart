import 'package:flutter/material.dart';

import '../models/prayer_alarm_rule.dart';
import '../services/prayer_alarm_service.dart';
import '../services/prayer_alarm_storage.dart';
import '../services/ringtone_service.dart';

class PrayerAlarmEditorScreen extends StatefulWidget {
  const PrayerAlarmEditorScreen({
    super.key,
    required this.rule,
  });

  final PrayerAlarmRule rule;

  @override
  State<PrayerAlarmEditorScreen> createState() => _PrayerAlarmEditorScreenState();
}

class _PrayerAlarmEditorScreenState extends State<PrayerAlarmEditorScreen> {
  late int offsetMinutes;
  late bool challengeEnabled;
  String? ringtonePath;
  String? ringtoneName;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    offsetMinutes = widget.rule.offsetMinutes;
    challengeEnabled = widget.rule.challengeEnabled;
    ringtonePath = widget.rule.ringtonePath;
    ringtoneName = widget.rule.ringtoneName;
  }

  String get offsetLabel {
    if (offsetMinutes == 0) return 'عند الأذان';
    if (offsetMinutes < 0) return 'قبل الأذان بـ ${offsetMinutes.abs()} دقيقة';
    return 'بعد الأذان بـ $offsetMinutes دقيقة';
  }

  Future<void> _pickRingtone() async {
    final choice = await RingtoneService.pickSystemRingtone();
    if (choice == null || !mounted) return;
    setState(() {
      ringtonePath = choice.path;
      ringtoneName = choice.name;
    });
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    final rule = widget.rule.copyWith(
      offsetMinutes: offsetMinutes,
      challengeEnabled: challengeEnabled,
      enabled: true,
      ringtonePath: ringtonePath,
      ringtoneName: ringtoneName,
    );
    try {
      await PrayerAlarmStorage.upsert(rule);
      await PrayerAlarmService.scheduleNext(rule);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر ضبط المنبه: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('منبه صلاة ${widget.rule.arabicName}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'منبه مرتبط بموعد الصلاة',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Shiftly سيحدّث الموعد تلقائيًا كل يوم حسب مواقيت الصلاة القادمة.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(offsetLabel, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Slider(
                      value: offsetMinutes.toDouble(),
                      min: -60,
                      max: 60,
                      divisions: 24,
                      label: offsetLabel,
                      onChanged: (value) =>
                          setState(() => offsetMinutes = value.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: challengeEnabled,
              onChanged: (value) => setState(() => challengeEnabled = value),
              title: const Text('تحدي الاستيقاظ'),
              subtitle: const Text('استخدم البازل عند رنين المنبه'),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor),
              ),
              leading: const Icon(Icons.music_note_rounded),
              title: const Text('نغمة المنبه'),
              subtitle: Text(ringtoneName ?? 'النغمة الافتراضية'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: _pickRingtone,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alarm_add_rounded),
              label: const Text('حفظ وتفعيل المنبه'),
            ),
          ],
        ),
      ),
    );
  }
}
