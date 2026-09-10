import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'models/shift_exception.dart';
import 'models/wake_alarm.dart';
import 'models/work_pattern.dart';
import 'screens/alarm_challenge_screen.dart';
import 'screens/main_shell.dart';
import 'screens/setup_screen.dart';
import 'services/alarm_service.dart';
import 'services/alarm_storage.dart';
import 'services/pattern_storage.dart';
import 'services/shift_exception_storage.dart';

class ShiftlyApp extends StatefulWidget {
  const ShiftlyApp({super.key});

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  WorkPattern? pattern;
  List<WakeAlarm> alarms = const [];
  List<ShiftException> shiftExceptions = const [];
  bool editingPattern = false;
  bool loaded = false;
  int? activeAlarmId;
  StreamSubscription<dynamic>? ringingSubscription;

  @override
  void initState() {
    super.initState();
    _loadState();
    ringingSubscription = Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        _openChallenge(alarm.id);
        break;
      }
    });
  }

  Future<void> _loadState() async {
    final values = await Future.wait<dynamic>([
      PatternStorage.load(),
      AlarmStorage.load(),
      ShiftExceptionStorage.load(),
    ]);
    if (!mounted) return;
    setState(() {
      pattern = values[0] as WorkPattern?;
      alarms = values[1] as List<WakeAlarm>;
      shiftExceptions = values[2] as List<ShiftException>;
      loaded = true;
    });
  }

  void _openChallenge(int alarmId) {
    if (activeAlarmId == alarmId) return;
    activeAlarmId = alarmId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        activeAlarmId = null;
        return;
      }
      navigator.push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlarmChallengeScreen(
          alarmId: alarmId,
          onCompleted: () {
            activeAlarmId = null;
            navigator.pop();
            unawaited(_rescheduleWakeAlarm(alarmId));
          },
        ),
      ));
    });
  }

  Future<void> _rescheduleWakeAlarm(int alarmId) async {
    final matches = alarms.where((alarm) => alarm.id == alarmId && alarm.enabled);
    if (matches.isEmpty) return;
    await AlarmService.scheduleWakeAlarm(matches.first);
  }

  Future<void> _savePattern(WorkPattern value) async {
    await PatternStorage.save(value);
    await AlarmService.replacePatternAlarms(value);
    if (!mounted) return;
    setState(() {
      pattern = value;
      editingPattern = false;
    });
  }

  Future<void> _addAlarm(TimeOfDay time, String label) async {
    final alarm = WakeAlarm(
      id: 1000000000 +
          DateTime.now().millisecondsSinceEpoch.remainder(900000000),
      hour: time.hour,
      minute: time.minute,
      label: label,
      enabled: true,
    );
    final updated = [...alarms, alarm];
    await AlarmStorage.save(updated);
    await AlarmService.scheduleWakeAlarm(alarm);
    if (!mounted) return;
    setState(() => alarms = updated);
  }

  Future<void> _toggleAlarm(WakeAlarm alarm, bool enabled) async {
    final updatedAlarm = alarm.copyWith(enabled: enabled);
    final updated = alarms
        .map((item) => item.id == alarm.id ? updatedAlarm : item)
        .toList();
    await AlarmStorage.save(updated);
    if (enabled) {
      await AlarmService.scheduleWakeAlarm(updatedAlarm);
    } else {
      await AlarmService.stopWakeAlarm(alarm.id);
    }
    if (!mounted) return;
    setState(() => alarms = updated);
  }

  Future<void> _deleteAlarm(WakeAlarm alarm) async {
    await AlarmService.stopWakeAlarm(alarm.id);
    final updated = alarms.where((item) => item.id != alarm.id).toList();
    await AlarmStorage.save(updated);
    if (!mounted) return;
    setState(() => alarms = updated);
  }

  Future<void> _addShiftException({
    required String title,
    required DateTime start,
    required DateTime end,
    required int alarmBeforeMinutes,
  }) async {
    final exception = ShiftException(
      id: 1950000000 +
          DateTime.now().millisecondsSinceEpoch.remainder(100000000),
      title: title,
      start: start,
      end: end,
      alarmBeforeMinutes: alarmBeforeMinutes,
    );
    final updated = [...shiftExceptions, exception]
      ..sort((a, b) => a.start.compareTo(b.start));
    await ShiftExceptionStorage.save(updated);
    await AlarmService.scheduleShiftException(
      exception,
      audioPath: pattern?.ringtonePath,
    );
    if (!mounted) return;
    setState(() => shiftExceptions = updated);
  }

  Future<void> _deleteShiftException(ShiftException exception) async {
    await AlarmService.stopShiftException(exception.id);
    final updated =
        shiftExceptions.where((item) => item.id != exception.id).toList();
    await ShiftExceptionStorage.save(updated);
    if (!mounted) return;
    setState(() => shiftExceptions = updated);
  }

  @override
  void dispose() {
    ringingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6D4AFF);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFEDE8FF),
          height: 72,
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: !loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : editingPattern
              ? SetupScreen(
                  onSaved: _savePattern,
                  onCancel: () => setState(() => editingPattern = false),
                )
              : MainShell(
                  pattern: pattern,
                  alarms: alarms,
                  shiftExceptions: shiftExceptions,
                  onEditPattern: () => setState(() => editingPattern = true),
                  onAddAlarm: _addAlarm,
                  onToggleAlarm: _toggleAlarm,
                  onDeleteAlarm: _deleteAlarm,
                  onAddShiftException: _addShiftException,
                  onDeleteShiftException: _deleteShiftException,
                ),
    );
  }
}
