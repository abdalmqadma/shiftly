import 'package:flutter/material.dart';
import '../models/wake_alarm.dart';
import '../services/ringtone_service.dart';

class AlarmEditorScreen extends StatefulWidget {
  const AlarmEditorScreen({super.key, this.alarm});

  final WakeAlarm? alarm;

  @override
  State<AlarmEditorScreen> createState() => _AlarmEditorScreenState();
}

class _AlarmEditorScreenState extends State<AlarmEditorScreen> {
  static const violet = Color(0xFF6D4AFF);
  static const surface = Color(0xFFFFFBF7);

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
    days = Set<int>.from(alarm?.weekdays ?? const [1, 2, 3, 4, 5, 6, 7]);
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
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          widget.alarm == null ? 'منبّه جديد' : 'تعديل المنبّه',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'حفظ',
              style: TextStyle(fontWeight: FontWeight.w900, color: violet),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _timeCard(),
            const SizedBox(height: 18),
            _section(
              title: 'تفاصيل المنبّه',
              child: TextField(
                controller: labelController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'مثال: الجامعة، الدوام، الجيم',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'أيام التكرار',
              child: _daysPicker(),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'الصوت',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: violet.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: violet),
                ),
                title: const Text('نغمة المنبّه',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(ringtone.name),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: _pickRingtone,
              ),
            ),
            const SizedBox(height: 14),
            _section(
              title: 'تخصيصات Shiftly',
              child: Column(
                children: [
                  _settingTile(
                    icon: Icons.calculate_outlined,
                    title: 'تحدي الاستيقاظ',
                    subtitle: 'ما ينطفي المنبّه قبل ما تكمل التحدي',
                    value: challenge,
                    onChanged: (value) => setState(() => challenge = value),
                  ),
                  const Divider(height: 1),
                  _settingTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sleepy-Me Protection',
                    subtitle: 'يحميك من إطفاء المنبّه وأنت نص نايم',
                    value: sleepyMe,
                    onChanged: (value) => setState(() => sleepyMe = value),
                  ),
                  const Divider(height: 1),
                  _settingTile(
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
                backgroundColor: violet,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.alarm_on_rounded),
              label: Text(
                widget.alarm == null ? 'إضافة المنبّه' : 'حفظ التعديلات',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE4DCFF)),
      ),
      child: Column(
        children: [
          const Text(
            'اسحب للأعلى أو للأسفل لتحديد الوقت',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6C6580)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 6),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                ),
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: _wheel(
                        controller: hourController,
                        count: 12,
                        valueBuilder: (index) => '${index + 1}'.padLeft(2, '0'),
                        onChanged: (index) => setState(() => hour12 = index + 1),
                      ),
                    ),
                    const Text(':',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    Expanded(
                      child: _wheel(
                        controller: minuteController,
                        count: 60,
                        valueBuilder: (index) => '$index'.padLeft(2, '0'),
                        onChanged: (index) => setState(() => minute = index),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: _wheel(
                        controller: periodController,
                        count: 2,
                        valueBuilder: (index) => index == 0 ? 'ص' : 'م',
                        onChanged: (index) => setState(() => periodIndex = index),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _nextLabel(),
            style: const TextStyle(color: Color(0xFF6C6580), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int index) valueBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 52,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.35,
      perspective: 0.003,
      squeeze: 0.95,
      overAndUnderCenterOpacity: .28,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          if (index == null) return null;
          return Center(
            child: Text(
              valueBuilder(index),
              style: const TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          child,
        ],
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((entry) {
        final selected = days.contains(entry.$1);
        return FilterChip(
          selected: selected,
          label: Text(entry.$2),
          selectedColor: violet.withValues(alpha: .14),
          checkmarkColor: violet,
          side: BorderSide(
            color: selected ? violet.withValues(alpha: .35) : Colors.grey.shade300,
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

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: violet),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: violet,
      onChanged: onChanged,
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
                child: Text('اختيار النغمة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.alarm_rounded, color: violet),
                title: const Text('نغمة المنبّه الافتراضية'),
                onTap: () => Navigator.pop(context, 0),
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded, color: violet),
                title: const Text('اختيار نغمة من الهاتف'),
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                leading: const Icon(Icons.library_music_rounded, color: violet),
                title: const Text('اختيار ملف صوتي مخصص'),
                onTap: () => Navigator.pop(context, 2),
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
    );
  }
}
