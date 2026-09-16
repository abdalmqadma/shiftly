import 'package:flutter/material.dart';

import '../models/prayer_alarm_rule.dart';
import '../services/prayer_alarm_storage.dart';
import 'prayer_alarm_editor_screen.dart';

class PrayerSyncResultScreen extends StatefulWidget {
  const PrayerSyncResultScreen({
    super.key,
    required this.rules,
  });

  final List<PrayerAlarmRule> rules;

  @override
  State<PrayerSyncResultScreen> createState() =>
      _PrayerSyncResultScreenState();
}

class _PrayerSyncResultScreenState extends State<PrayerSyncResultScreen> {
  late List<PrayerAlarmRule> rules;

  @override
  void initState() {
    super.initState();
    rules = [...widget.rules];
  }

  Future<void> _edit(PrayerAlarmRule rule) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PrayerAlarmEditorScreen(rule: rule),
      ),
    );

    final saved = await PrayerAlarmStorage.load();
    if (!mounted) return;
    setState(() {
      rules = [
        for (final current in rules)
          saved.firstWhere(
            (item) => item.prayer == current.prayer,
            orElse: () => current,
          ),
      ];
    });
  }

  String _offsetLabel(PrayerAlarmRule rule) {
    if (rule.offsetMinutes == 0) return 'عند الأذان';
    if (rule.offsetMinutes < 0) {
      return 'قبل الأذان بـ ${rule.offsetMinutes.abs()} دقيقة';
    }
    return 'بعد الأذان بـ ${rule.offsetMinutes} دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledCount = rules.where((rule) => rule.enabled).length;

    return Scaffold(
      appBar: AppBar(title: const Text('منيب × Shiftly')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'تمت مزامنة منبهات الصلاة',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تم تفعيل $enabledCount منبه. سيحدّث Shiftly المواعيد تلقائيًا كل يوم.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    enabled: rule.enabled,
                    leading: Icon(
                      rule.enabled
                          ? Icons.alarm_on_rounded
                          : Icons.alarm_off_rounded,
                    ),
                    title: Text('صلاة ${rule.arabicName}'),
                    subtitle: Text(
                      rule.enabled
                          ? '${_offsetLabel(rule)} • ${rule.challengeEnabled ? 'مع بازل' : 'بدون بازل'}'
                          : 'غير مفعّل',
                    ),
                    trailing: rule.enabled
                        ? const Icon(Icons.chevron_left_rounded)
                        : null,
                    onTap: rule.enabled ? () => _edit(rule) : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على أي صلاة مفعّلة لتغيير النغمة أو تعديل إعدادها مباشرة داخل Shiftly.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );
  }
}
