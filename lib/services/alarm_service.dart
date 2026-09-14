import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_colors.dart';
import '../models/shift_exception.dart';
import '../models/wake_alarm.dart';
import '../models/work_pattern.dart';
import 'alarm_storage.dart';
import 'shift_exception_storage.dart';

class AlarmReadiness {
  const AlarmReadiness({
    required this.notificationsGranted,
    required this.exactAlarmGranted,
  });

  final bool notificationsGranted;
  final bool exactAlarmGranted;

  bool get ready => notificationsGranted && exactAlarmGranted;
}

class AlarmService {
  const AlarmService._();

  static const int _patternQueueSize = 40;

  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  static Future<AlarmReadiness> readiness() async {
    if (!Platform.isAndroid) {
      return const AlarmReadiness(
        notificationsGranted: true,
        exactAlarmGranted: true,
      );
    }
    final notifications = await Permission.notification.status;
    final exactAlarm = await Permission.scheduleExactAlarm.status;
    return AlarmReadiness(
      notificationsGranted: notifications.isGranted,
      exactAlarmGranted: exactAlarm.isGranted,
    );
  }

  static Future<void> scheduleWakeAlarm(WakeAlarm alarm) async {
    if (!alarm.enabled) return;
    await requestPermissions();
    await _set(
      id: alarm.id,
      dateTime: alarm.nextOccurrence(),
      title: alarm.label,
      audioPath: alarm.ringtonePath,
    );
  }

  static Future<void> stopWakeAlarm(int id) => Alarm.stop(id);

  static Future<void> rescheduleOneTimeShiftAlarm({
    required int id,
    required String title,
    required DateTime oldTime,
    required DateTime newTime,
    String? audioPath,
  }) async {
    await requestPermissions();
    await Alarm.stop(id);
    if (!newTime.isAfter(DateTime.now())) return;
    await _set(
      id: id,
      dateTime: newTime,
      title: title,
      audioPath: audioPath,
    );
  }

  static Future<void> scheduleShiftException(
    ShiftException exception, {
    String? audioPath,
  }) async {
    if (!exception.alarmTime.isAfter(DateTime.now())) return;
    await requestPermissions();
    await _set(
      id: exception.id,
      dateTime: exception.alarmTime,
      title: exception.title,
      audioPath: audioPath,
    );
  }

  static Future<void> stopShiftException(int id) => Alarm.stop(id);

  static Future<void> replacePatternAlarms(WorkPattern pattern) async {
    await requestPermissions();

    final wakeIds = (await AlarmStorage.load()).map((alarm) => alarm.id).toSet();
    final exceptionIds =
        (await ShiftExceptionStorage.load()).map((item) => item.id).toSet();
    final existing = await Alarm.getAlarms();
    for (final alarm in existing) {
      if (wakeIds.contains(alarm.id) || exceptionIds.contains(alarm.id)) {
        continue;
      }
      await Alarm.stop(alarm.id);
    }

    await replenishPatternAlarms(pattern);
  }

  static Future<void> replenishPatternAlarms(WorkPattern pattern) async {
    await requestPermissions();

    final existingIds = (await Alarm.getAlarms()).map((alarm) => alarm.id).toSet();
    final now = DateTime.now();
    var covered = 0;
    var cycleIndex =
        now.difference(pattern.cycleStart).inMinutes ~/ pattern.cycleMinutes - 1;

    while (covered < _patternQueueSize) {
      final base = pattern.cycleStart
          .add(Duration(minutes: cycleIndex * pattern.cycleMinutes));

      for (final shift in pattern.shifts) {
        final shiftStart =
            base.add(Duration(minutes: shift.startOffsetMinutes));
        final alarmTime =
            shiftStart.subtract(Duration(minutes: pattern.alarmBeforeMinutes));

        if (!alarmTime.isAfter(now)) continue;

        final id = patternAlarmIdFor(alarmTime);
        if (!existingIds.contains(id)) {
          await _set(
            id: id,
            dateTime: alarmTime,
            title: shift.name,
            audioPath: pattern.ringtonePath,
          );
          existingIds.add(id);
        }

        covered++;
        if (covered == _patternQueueSize) break;
      }
      cycleIndex++;
    }
  }

  static Future<void> scheduleTestAlarm({String? audioPath}) async {
    await requestPermissions();
    final time = DateTime.now().add(const Duration(minutes: 1));
    await _set(
      id: 1900000000 + DateTime.now().second,
      dateTime: time,
      title: 'منبّه تجريبي',
      audioPath: audioPath,
    );
  }

  static Future<void> _set({
    required int id,
    required DateTime dateTime,
    required String title,
    String? audioPath,
  }) async {
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: id,
        dateTime: dateTime,
        assetAudioPath: audioPath,
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
          iconColor: AppColors.primary,
        ),
      ),
    );
  }

  static int patternAlarmIdFor(DateTime time) =>
      time.millisecondsSinceEpoch.remainder(900000000) + 10000000;
}
