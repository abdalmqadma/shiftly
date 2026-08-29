import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'models/work_pattern.dart';
import 'screens/alarm_challenge_screen.dart';
import 'screens/main_shell.dart';
import 'screens/setup_screen.dart';
import 'services/alarm_service.dart';

class ShiftlyApp extends StatefulWidget {
  const ShiftlyApp({super.key});

  @override
  State<ShiftlyApp> createState() => _ShiftlyAppState();
}

class _ShiftlyAppState extends State<ShiftlyApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  WorkPattern? pattern;
  bool editing = false;
  int? activeAlarmId;
  StreamSubscription<dynamic>? ringingSubscription;

  @override
  void initState() {
    super.initState();
    ringingSubscription = Alarm.ringing.listen((alarmSet) {
      for (final alarm in alarmSet.alarms) {
        _openChallenge(alarm.id);
        break;
      }
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
          },
        ),
      ));
    });
  }

  Future<void> _savePattern(WorkPattern value) async {
    await AlarmService.replacePatternAlarms(value);
    if (!mounted) return;
    setState(() {
      pattern = value;
      editing = false;
    });
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFEDE8FF),
          height: 72,
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: pattern == null || editing
          ? SetupScreen(onSaved: _savePattern)
          : MainShell(
              pattern: pattern!,
              onEditPattern: () => setState(() => editing = true),
            ),
    );
  }
}
