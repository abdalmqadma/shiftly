import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/shift_exception.dart';
import '../models/wake_alarm.dart';
import '../models/work_pattern.dart';
import '../services/alarm_service.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'shift_exceptions_screen.dart';
import 'wake_alarms_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.pattern,
    required this.alarms,
    required this.shiftExceptions,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onEditPattern,
    required this.onAddAlarm,
    required this.onUpdateAlarm,
    required this.onToggleAlarm,
    required this.onDeleteAlarm,
    required this.onEditTodayShiftAlarm,
    required this.onAddShiftException,
    required this.onDeleteShiftException,
  });

  final WorkPattern? pattern;
  final List<WakeAlarm> alarms;
  final List<ShiftException> shiftExceptions;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;
  final VoidCallback onEditPattern;
  final Future<void> Function(WakeAlarm alarm) onAddAlarm;
  final Future<void> Function(WakeAlarm alarm) onUpdateAlarm;
  final Future<void> Function(WakeAlarm alarm, bool enabled) onToggleAlarm;
  final Future<void> Function(WakeAlarm alarm) onDeleteAlarm;
  final Future<void> Function({
    required int alarmId,
    required String title,
    required DateTime oldTime,
    required DateTime newTime,
  }) onEditTodayShiftAlarm;
  final Future<void> Function({
    required String title,
    required DateTime start,
    required DateTime end,
    required int alarmBeforeMinutes,
  }) onAddShiftException;
  final Future<void> Function(ShiftException exception) onDeleteShiftException;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      WakeAlarmsScreen(
        alarms: widget.alarms,
        pattern: widget.pattern,
        onAdd: widget.onAddAlarm,
        onUpdate: widget.onUpdateAlarm,
        onToggle: widget.onToggleAlarm,
        onDelete: widget.onDeleteAlarm,
        onEditTodayShiftAlarm: widget.onEditTodayShiftAlarm,
      ),
      _shiftMode(),
      _settings(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shiftly',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
              Text('Wake-up system',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ]),
      ),
      body: pages[page],
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.alarm_outlined), label: 'المنبّهات'),
          NavigationDestination(
              icon: Icon(Icons.autorenew_rounded), label: 'الشفتات'),
          NavigationDestination(
              icon: Icon(Icons.tune_rounded), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _shiftMode() {
    final pattern = widget.pattern;
    if (pattern == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 18),
          const Text('وضع الشفتات',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'ميزة اختيارية للي دوامهم بنظام دورات متكررة.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                const Icon(Icons.work_history_outlined,
                    size: 58, color: AppColors.primary),
                const SizedBox(height: 18),
                const Text('فعّل جدول الشفتات',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'مثال: 48 ساعة دوام / 24 ساعة راحة، أو أي دورة خاصة فيك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: widget.onEditPattern,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إعداد نظام الشفتات'),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    return Column(children: [
      Expanded(child: HomeScreen(pattern: pattern)),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.danger.withValues(alpha: .12),
              child: const Icon(Icons.emergency_outlined, color: AppColors.danger),
            ),
            title: const Text('طوارئ واستثناءات الشفتات',
                style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(widget.shiftExceptions.isEmpty
                ? 'تغطية مكان شخص أو شفت إضافي ليوم محدد'
                : '${widget.shiftExceptions.length} استثناءات محفوظة'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => _openShiftExceptions(pattern),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CalendarScreen(pattern: pattern),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('عرض التقويم'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: widget.onEditPattern,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل الشفتات'),
            ),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _openShiftExceptions(WorkPattern pattern) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ShiftExceptionsScreen(
          exceptions: widget.shiftExceptions,
          defaultAlarmBeforeMinutes: pattern.alarmBeforeMinutes,
          onAdd: widget.onAddShiftException,
          onDelete: widget.onDeleteShiftException,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _settings() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('الإعدادات',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المظهر',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('النظام'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('فاتح'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('داكن'),
                      ),
                    ],
                    selected: {widget.themeMode},
                    onSelectionChanged: (value) {
                      widget.onThemeModeChanged(value.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.health_and_safety_outlined,
            title: 'فحص جاهزية المنبّه',
            subtitle: 'الإشعارات + صلاحية المنبّه الدقيق',
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: _showReadiness,
          ),
          const SizedBox(height: 12),
          _settingsTile(
            icon: Icons.alarm_on_rounded,
            title: 'اختبار المنبّه',
            subtitle: 'يرن بعد دقيقة ويطلب تحدي الحساب',
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () async {
              await AlarmService.scheduleTestAlarm(
                audioPath: widget.pattern?.ringtonePath,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم ضبط الاختبار بعد دقيقة')),
              );
            },
          ),
          if (widget.pattern != null) ...[
            const SizedBox(height: 12),
            _settingsTile(
              icon: Icons.edit_calendar_rounded,
              title: 'تعديل نظام المناوبة',
              subtitle:
                  '${widget.pattern!.shifts.length} شِفتات داخل دورة مدتها ${widget.pattern!.cycleMinutes ~/ 60} ساعة',
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: widget.onEditPattern,
            ),
          ],
        ],
      );

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Future<void> _showReadiness() async {
    final result = await AlarmService.readiness();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.ready ? 'Shiftly جاهز ✅' : 'في إعدادات ناقصة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _readinessRow('الإشعارات', result.notificationsGranted),
            const SizedBox(height: 12),
            _readinessRow('المنبّهات الدقيقة', result.exactAlarmGranted),
          ],
        ),
        actions: [
          if (!result.ready)
            TextButton(
              onPressed: () async {
                await AlarmService.requestPermissions();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('طلب الصلاحيات'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  Widget _readinessRow(String label, bool granted) => Row(children: [
        Icon(
          granted ? Icons.check_circle : Icons.error_outline,
          color: granted ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(granted ? 'جاهز' : 'مطلوب',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ]);
}
