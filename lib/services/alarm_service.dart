import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/work_pattern.dart';

class AlarmService {
  const AlarmService._();

  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  static Future<void> replacePatternAlarms(WorkPattern pattern) async {
    await requestPermissions();

    final existing = await Alarm.getAlarms();
    for (final alarm in existing) {
      await Alarm.stop(alarm.id);
    }

    final now = DateTime.now();
    var scheduled = 0;
    var cycleIndex =
        now.difference(pattern.cycleStart).inMinutes ~/ pattern.cycleMinutes - 1;

    while (scheduled < 40) {
      final base = pattern.cycleStart
          .add(Duration(minutes: cycleIndex * pattern.cycleMinutes));

      for (final shift in pattern.shifts) {
        final shiftStart =
            base.add(Duration(minutes: shift.startOffsetMinutes));
        final alarmTime = shiftStart
            .subtract(Duration(minutes: pattern.alarmBeforeMinutes));

        if (alarmTime.isAfter(now)) {
          await _set(
            id: _idFor(alarmTime),
            dateTime: alarmTime,
            title: shift.name,
          );
          scheduled++;
          if (scheduled == 40) break;
        }
      }
      cycleIndex++;
    }
  }

  static Future<void> scheduleTestAlarm() async {
    await requestPermissions();
    final time = DateTime.now().add(const Duration(minutes: 1));
    await _set(id: _idFor(time), dateTime: time, title: 'منبّه تجريبي');
  }

  static Future<void> _set({
    required int id,
    required DateTime dateTime,
    required String title,
  }) async {
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: dateTime,
        loopAudio: true,
        vibrate: true,
        androidFullScreenIntent: true,
        androidStopAlarmOnTermination: false,
        androidStaleAfter: const Duration(minutes: 15),
        volumeSettings: VolumeSettings.fade(
          volume: 1,
          fadeDuration: const Duration(seconds: 12),
          volumeEnforced: true,
        ),
        notificationSettings: NotificationSettings(
          title: 'حان وقت الاستيقاظ',
          body: '$title — افتح Shiftly وأكمل التحدي',
          stopButton: null,
          androidStopAlarmOnDismiss: false,
          iconColor: const Color(0xFF6D4AFF),
        ),
      ),
    );
  }

  static int _idFor(DateTime time) =>
      time.millisecondsSinceEpoch.remainder(2147483647);
}
