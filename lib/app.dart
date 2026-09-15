import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'models/prayer_alarm_rule.dart';
import 'models/shift_exception.dart';
import 'models/wake_alarm.dart';
import 'models/work_pattern.dart';
import 'screens/alarm_challenge_screen.dart';
import 'screens/alarm_dismiss_screen.dart';
import 'screens/main_shell.dart';
import 'screens/prayer_alarm_editor_screen.dart';
import 'screens/setup_screen.dart';
import 'services/alarm_service.dart';
import 'services/alarm_storage.dart';
import 'services/pattern_storage.dart';
import 'services/prayer_alarm_service.dart';
import 'services/prayer_alarm_storage.dart';
import 'services/shift_exception_storage.dart';
import 'services/theme_storage.dart';

class ShiftlyApp extends StatefulWidget {
  const ShiftlyApp({super.key});

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks appLinks = AppLinks();

  WorkPattern? pattern;
  List<WakeAlarm> alarms = const [];
  List<ShiftException> shiftExceptions = const [];
  ThemeMode themeMode = ThemeMode.system;
  bool editingPattern = false;
  bool loaded = false;
  int? activeAlarmId;
  Uri? pendingPrayerLink;
  StreamSubscription<dynamic>? ringingSubscription;
  StreamSubscription<Uri>? linkSubscription;

  @override
  void initState() {
    super.initState();
    _loadState();
    _initLinks();
    ringingSubscription = Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        unawaited(_handleRingingAlarm(alarm.id));
        break;
      }
    });
  }

  Future<void> _initLinks() async {
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handleIncomingUri(initial);
      linkSubscription = appLinks.uriLinkStream.listen(_handleIncomingUri);
    } catch (_) {
      // A malformed external link must never prevent Shiftly from starting.
    }
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme != 'shiftly' || uri.host != 'prayer-alarm') return;
    pendingPrayerLink = uri;
    if (loaded) _openPendingPrayerEditor();
  }

  Future<void> _openPendingPrayerEditor() async {
    final uri = pendingPrayerLink;
    final navigator = navigatorKey.currentState;
    if (uri == null || navigator == null) return;

    final prayer = uri.queryParameters['prayer'];
    final latitude = double.tryParse(uri.queryParameters['lat'] ?? '');
    final longitude = double.tryParse(uri.queryParameters['lon'] ?? '');
    final method = int.tryParse(uri.queryParameters['method'] ?? '');
    final school = int.tryParse(uri.queryParameters['school'] ?? '') ?? 0;
    final tune = uri.queryParameters['tune'];
    const allowed = {'Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'};

    if (prayer == null ||
        !allowed.contains(prayer) ||
        latitude == null ||
        longitude == null ||
        method == null) {
      pendingPrayerLink = null;
      return;
    }

    final savedRules = await PrayerAlarmStorage.load();
    PrayerAlarmRule? existing;
    for (final rule in savedRules) {
      if (rule.prayer == prayer) {
        existing = rule;
        break;
      }
    }

    final rule = PrayerAlarmRule(
      prayer: prayer,
      latitude: latitude,
      longitude: longitude,
      method: method,
      school: school,
      tune: tune,
      offsetMinutes: existing?.offsetMinutes ?? 0,
      challengeEnabled: existing?.challengeEnabled ?? true,
      enabled: existing?.enabled ?? true,
      ringtonePath: existing?.ringtonePath,
      ringtoneName: existing?.ringtoneName,
    );

    pendingPrayerLink = null;
    if (!mounted) return;
    await navigator.push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PrayerAlarmEditorScreen(rule: rule),
      ),
    );
  }

  Future<void> _loadState() async {
    final values = await Future.wait<dynamic>([
      PatternStorage.load(),
      AlarmStorage.load(),
      ShiftExceptionStorage.load(),
      ThemeStorage.load(),
    ]);

    final loadedPattern = values[0] as WorkPattern?;
    if (loadedPattern != null) {
      unawaited(AlarmService.replenishPatternAlarms(loadedPattern));
    }
    unawaited(PrayerAlarmService.replenishAll());

    if (!mounted) return;
    setState(() {
      pattern = loadedPattern;
      alarms = values[1] as List<WakeAlarm>;
      shiftExceptions = values[2] as List<ShiftException>;
      themeMode = values[3] as ThemeMode;
      loaded = true;
    });

    if (pendingPrayerLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_openPendingPrayerEditor());
      });
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await ThemeStorage.save(mode);
    if (!mounted) return;
    setState(() => themeMode = mode);
  }

  Future<void> _handleRingingAlarm(int alarmId) async {
    if (PrayerAlarmService.isPrayerAlarmId(alarmId)) {
      final rules = await PrayerAlarmStorage.load();
      PrayerAlarmRule? rule;
      for (final item in rules) {
        if (item.alarmId == alarmId) {
          rule = item;
          break;
        }
      }
      if (rule != null && !rule.challengeEnabled) {
        _openSimpleDismiss(alarmId);
        return;
      }
    }
    _openChallenge(alarmId);
  }

  void _openSimpleDismiss(int alarmId) {
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
        builder: (_) => AlarmDismissScreen(
          alarmId: alarmId,
          onCompleted: () {
            activeAlarmId = null;
            navigator.pop();
            unawaited(_handleAlarmCompleted(alarmId));
          },
        ),
      ));
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
            unawaited(_handleAlarmCompleted(alarmId));
          },
        ),
      ));
    });
  }

  Future<void> _handleAlarmCompleted(int alarmId) async {
    if (PrayerAlarmService.isPrayerAlarmId(alarmId)) {
      final rules = await PrayerAlarmStorage.load();
      for (final rule in rules) {
        if (rule.alarmId == alarmId && rule.enabled) {
          await PrayerAlarmService.scheduleNext(rule);
          return;
        }
      }
      return;
    }

    final manualMatches =
        alarms.where((alarm) => alarm.id == alarmId && alarm.enabled);
    if (manualMatches.isNotEmpty) {
      await AlarmService.scheduleWakeAlarm(manualMatches.first);
      return;
    }

    if (!AlarmService.isPatternAlarmId(alarmId)) return;
    final currentPattern = pattern;
    if (currentPattern == null) return;
    await AlarmService.replenishPatternAlarms(currentPattern);
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

  Future<void> _addAlarm(WakeAlarm draft) async {
    final alarm = WakeAlarm(
      id: 1000000000 +
          DateTime.now().millisecondsSinceEpoch.remainder(900000000),
      hour: draft.hour,
      minute: draft.minute,
      label: draft.label,
      enabled: true,
      weekdays: draft.weekdays,
      challengeEnabled: draft.challengeEnabled,
      sleepyMeProtection: draft.sleepyMeProtection,
      proofOfAwake: draft.proofOfAwake,
      ringtonePath: draft.ringtonePath,
      ringtoneName: draft.ringtoneName,
    );
    final updated = [...alarms, alarm];
    await AlarmStorage.save(updated);
    await AlarmService.scheduleWakeAlarm(alarm);
    if (!mounted) return;
    setState(() => alarms = updated);
  }

  Future<void> _updateAlarm(WakeAlarm alarm) async {
    final updated = alarms.map((item) => item.id == alarm.id ? alarm : item).toList();
    await AlarmStorage.save(updated);
    await AlarmService.stopWakeAlarm(alarm.id);
    if (alarm.enabled) await AlarmService.scheduleWakeAlarm(alarm);
    if (!mounted) return;
    setState(() => alarms = updated);
  }

  Future<void> _toggleAlarm(WakeAlarm alarm, bool enabled) =>
      _updateAlarm(alarm.copyWith(enabled: enabled));

  Future<void> _deleteAlarm(WakeAlarm alarm) async {
    await AlarmService.stopWakeAlarm(alarm.id);
    final updated = alarms.where((item) => item.id != alarm.id).toList();
    await AlarmStorage.save(updated);
    if (!mounted) return;
    setState(() => alarms = updated);
  }

  Future<void> _editTodayShiftAlarm({
    required int alarmId,
    required String title,
    required DateTime oldTime,
    required DateTime newTime,
  }) async {
    await AlarmService.rescheduleOneTimeShiftAlarm(
      id: alarmId,
      title: title,
      oldTime: oldTime,
      newTime: newTime,
      audioPath: pattern?.ringtonePath,
    );
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
    await AlarmService.scheduleShiftException(exception, audioPath: pattern?.ringtonePath);
    if (!mounted) return;
    setState(() => shiftExceptions = updated);
  }

  Future<void> _deleteShiftException(ShiftException exception) async {
    await AlarmService.stopShiftException(exception.id);
    final updated = shiftExceptions.where((item) => item.id != exception.id).toList();
    await ShiftExceptionStorage.save(updated);
    if (!mounted) return;
    setState(() => shiftExceptions = updated);
  }

  @override
  void dispose() {
    ringingSubscription?.cancel();
    linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
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
                  themeMode: themeMode,
                  onThemeModeChanged: _setThemeMode,
                  onEditPattern: () => setState(() => editingPattern = true),
                  onAddAlarm: _addAlarm,
                  onUpdateAlarm: _updateAlarm,
                  onToggleAlarm: _toggleAlarm,
                  onDeleteAlarm: _deleteAlarm,
                  onEditTodayShiftAlarm: _editTodayShiftAlarm,
                  onAddShiftException: _addShiftException,
                  onDeleteShiftException: _deleteShiftException,
                ),
    );
  }
}
