import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmDismissScreen extends StatelessWidget {
  const AlarmDismissScreen({
    super.key,
    required this.alarmId,
    required this.onCompleted,
  });

  final int alarmId;
  final VoidCallback onCompleted;

  Future<void> _dismiss() async {
    await Alarm.stop(alarmId);
    onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm_rounded, size: 88),
              const SizedBox(height: 24),
              Text(
                'حان وقت الاستيقاظ',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'منبه Shiftly يعمل الآن',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.alarm_off_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('إيقاف المنبه'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
