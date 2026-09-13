import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_section_card.dart';
import '../core/widgets/app_setting_switch_tile.dart';
import '../core/widgets/time_wheel_picker.dart';
import '../models/wake_alarm.dart';
import '../services/ringtone_service.dart';

class AlarmEditorResult {
  const AlarmEditorResult._({this.alarm, this.deleteRequested = false});

  final WakeAlarm? alarm;
  final bool deleteRequested;

  factory AlarmEditorResult.save(WakeAlarm alarm) =>
      AlarmEditorResult._(alarm: alarm);

  const factory AlarmEditorResult.delete() = _DeleteAlarmEditorResult;
}

class _DeleteAlarmEditorResult extends AlarmEditorResult {
  const _DeleteAlarmEditorResult()
      : super._(alarm: null, deleteRequested: true);
}

class AlarmEditorScreen extends StatefulWidget {
  const AlarmEditorScreen({super.key, this.alarm});

  final WakeAlarm? alarm;

  @override
  State<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends State<AlarmEditorScreen> {
  late int hour12;
  late int minute;
  late int periodIndex;
  late TextEditingController labelController;
  late Set<int> days;
  late bool challenge;
  late bool sleepyMe;
  late bool proofOfAwake;
  late RingtoneChoice ringtone;

  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController periodController;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    final initialHour24 = alarm?.hour ?? TimeOfDay.now().hour;
    hour12 = initialHour24 % 12 == 0 ? 12 : initialHour24 % 12;
    minute = alarm?.minute ?? TimeOfDay.now().minute;
    periodIndex = initialHour24 >= 12 ? 1 : 0;
    labelController = TextEditingController(text: alarm?.label ?? 'استيقاظ');
    days = Set<int>.from(
      alarm?.weekdays ?? const [1, 2, 3, 4, 5, 6, 7],
    );
    challenge = alarm?.challengeEnabled ?? true;
    sleepyMe = alarm?.sleepyMeProtection ?? true;
    proofOfAwake = alarm?.proofOfAwake ?? false;
    ringtone = RingtoneChoice(
      name: alarm?.ringtoneName ?? RingtoneChoice.systemDefault.name,
      path: alarm?.ringtonePath,
    );

    hourController = FixedExtentScrollController(initialItem: hour12 - 1);
    minuteController = FixedExtentScrollController(initialItem: minute);
    periodController = FixedExtentScrollController(initialItem: periodIndex);
  }

  @override
  void dispose() {
    labelController.dispose();
    hourController.dispose();
    minuteController.dispose();
    periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.alarm == null ? 'منبّه جديد' : 'تعديل المنبّه',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'حفظ',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TimeWheelPicker(
              hourController: hourController,
              minuteController: minuteController,
              periodController: periodController,
              onHourChanged: (index) => setState(() => hour12 = index + 1),
              onMinuteChanged: (index) => setState(() => minute = index),
              onPeriodChanged: (index) => setState(() => periodIndex = index),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _nextLabel(),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppSectionCard(
              title: 'تفاصيل المنبّه',
              child: TextField(
                controller: labelController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'مثال: الجامعة، الدوام، الجيم',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'أيام التكرار',
              child: _daysPicker(),
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'الصوت',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'نغمة المنبّه',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(ringtone.name),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: _pickRingtone,
              ),
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              title: 'تخصيصات Shiftly',
              child: Column(
                children: [
                  AppSettingSwitchTile(
                    icon: Icons.calculate_outlined,
                    title: 'تحدي الاستيقاظ',
                    subtitle: 'ما ينطفي المنبّه قبل ما تكمل التحدي',
                    value: challenge,
                    onChanged: (value) => setState(() => challenge = value),
                  ),
                  const Divider(height: 1),
                  AppSettingSwitchTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sleepy-Me Protection',
                    subtitle: 'يحميك من إطفاء المنبّه وأنت نص نايم',
                    value: sleepyMe,
                    onChanged: (value) => setState(() => sleepyMe = value),
                  ),
                  const Divider(height: 1),
                  AppSettingSwitchTile(
                    icon: Icons.verified_outlined,
                    title: 'إثبات الاستيقاظ',
                    subtitle: 'تأكيد إضافي بعد ما توقف المنبّه',
                    value: proofOfAwake,
                    onChanged: (value) => setState(() => proofOfAwake = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(56),
              ),
              icon: const Icon(Icons.alarm_on_rounded),
              label: Text(
                widget.alarm == null ? 'إضافة المنبّه' : 'حفظ التعديلات',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (widget.alarm != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _requestDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withValues(alpha: .45),
                  ),
                  minimumSize: const Size.fromHeight(54),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'حذف المنبّه',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _daysPicker() {
    const values = [
      (7, 'أحد'),
      (1, 'إثن'),
      (2, 'ثلا'),
      (3, 'أرب'),
      (4, 'خمي'),
      (5, 'جمع'),
      (6, 'سبت'),
    ];
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((entry) {
        final selected = days.contains(entry.$1);
        return FilterChip(
          selected: selected,
          label: Text(entry.$2),
          selectedColor: AppColors.primary.withValues(alpha: .14),
          checkmarkColor: AppColors.primary,
          side: BorderSide(
            color: selected
                ? AppColors.primary.withValues(alpha: .35)
                : scheme.outlineVariant,
          ),
          onSelected: (value) {
            setState(() {
              if (value) {
                days.add(entry.$1);
              } else if (days.length > 1) {
                days.remove(entry.$1);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Future<void> _pickRingtone() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختيار النغمة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 10),
              _ringtoneOption(
                icon: Icons.alarm_rounded,
                title: 'نغمة المنبّه الافتراضية',
                value: 0,
              ),
              _ringtoneOption(
                icon: Icons.phone_android_rounded,
                title: 'اختيار نغمة من الهاتف',
                value: 1,
              ),
              _ringtoneOption(
                icon: Icons.library_music_rounded,
                title: 'اختيار ملف صوتي مخصص',
                value: 2,
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 0) {
      setState(() => ringtone = RingtoneChoice.systemDefault);
      return;
    }

    final selected = choice == 1
        ? await RingtoneService.pickSystemRingtone()
        : await RingtoneService.pickMediaTone();
    if (selected != null && mounted) {
      setState(() => ringtone = selected);
    }
  }

  Widget _ringtoneOption({
    required IconData icon,
    required String title,
    required int value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      onTap: () => Navigator.pop(context, value),
    );
  }

  int get _hour24 {
    if (periodIndex == 0) return hour12 == 12 ? 0 : hour12;
    return hour12 == 12 ? 12 : hour12 + 12;
  }

  String _nextLabel() {
    final probe = WakeAlarm(
      id: widget.alarm?.id ?? 0,
      hour: _hour24,
      minute: minute,
      label: labelController.text,
      enabled: true,
      weekdays: days.toList(),
    );
    final next = probe.nextOccurrence();
    final now = DateTime.now();
    final diff = next.difference(now);
    if (diff.inDays >= 1) {
      return 'الرنين القادم بعد ${diff.inDays} يوم و${diff.inHours % 24} ساعة';
    }
    if (diff.inHours >= 1) {
      return 'الرنين القادم بعد ${diff.inHours} ساعة و${diff.inMinutes % 60} دقيقة';
    }
    return 'الرنين القادم بعد ${diff.inMinutes.clamp(1, 59)} دقيقة';
  }

  void _save() {
    final label = labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسمًا للمنبّه')),
      );
      return;
    }

    final old = widget.alarm;
    Navigator.pop(
      context,
      AlarmEditorResult.save(
        WakeAlarm(
          id: old?.id ?? 0,
          hour: _hour24,
          minute: minute,
          label: label,
          enabled: old?.enabled ?? true,
          weekdays: days.toList()..sort(),
          challengeEnabled: challenge,
          sleepyMeProtection: sleepyMe,
          proofOfAwake: proofOfAwake,
          ringtonePath: ringtone.path,
          ringtoneName: ringtone.name,
        ),
      ),
    );
  }

  Future<void> _requestDelete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف المنبّه؟'),
            content: Text(widget.alarm!.label),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    Navigator.pop(context, const AlarmEditorResult.delete());
  }
}
