import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/work_pattern.dart';
import '../services/schedule_calculator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.pattern});
  final WorkPattern pattern;

  @override
  Widget build(BuildContext context) {
    final calculator = ScheduleCalculator(pattern);
    final now = DateTime.now();
    final moment = calculator.stateAt(now);
    final next = calculator.nextShiftStart(now);
    final alarm = next.subtract(Duration(minutes: pattern.alarmBeforeMinutes));
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('نظرة سريعة',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          'جدولك الحقيقي، بدون مواعيد مفترضة',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        _currentStatus(context, moment),
        const SizedBox(height: 12),
        _statusLegend(context),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المنبّه القادم',
                  style: TextStyle(color: Colors.white70)),
              Text(
                _time(alarm),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(_date(alarm),
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text('تفاصيل الدورة',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('${pattern.dutyMinutes ~/ 60}', 'ساعة دوام', AppColors.shiftWork),
          const SizedBox(width: 9),
          _stat('${pattern.offMinutes ~/ 60}', 'ساعة إجازة', AppColors.shiftOff),
          const SizedBox(width: 9),
          _stat('${pattern.shifts.length}', 'شِفتات', AppColors.primary),
        ]),
      ],
    );
  }

  Widget _currentStatus(BuildContext context, ScheduleMoment moment) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.currentMarker,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text('أنت هنا الآن',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const Spacer(),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _stateColor(moment.state),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              moment.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _statusLegend(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendDot(color: AppColors.currentMarker, label: 'أنت هنا'),
        _LegendDot(color: AppColors.shiftWork, label: 'دوام'),
        _LegendDot(color: AppColors.shiftRest, label: 'راحة'),
        _LegendDot(color: AppColors.shiftOff, label: 'إجازة'),
      ],
    );
  }

  Color _stateColor(ScheduleState state) => switch (state) {
        ScheduleState.work => AppColors.shiftWork,
        ScheduleState.rest => AppColors.shiftRest,
        ScheduleState.off => AppColors.shiftOff,
      };

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 25, fontWeight: FontWeight.w900)),
              Text(label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'ص' : 'م'}';
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
