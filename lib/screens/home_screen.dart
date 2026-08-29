import 'package:flutter/material.dart';
import '../models/work_pattern.dart';
import '../services/schedule_calculator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.pattern});
  final WorkPattern pattern;

  static const violet = Color(0xFF6D4AFF);
  static const coral = Color(0xFFFF6B6B);
  static const mint = Color(0xFF38BFA0);
  static const amber = Color(0xFFFFB84D);

  @override
  Widget build(BuildContext context) {
    final calculator = ScheduleCalculator(pattern);
    final moment = calculator.stateAt(DateTime.now());
    final next = calculator.nextShiftStart(DateTime.now());
    final alarm =
        next.subtract(Duration(minutes: pattern.alarmBeforeMinutes));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('نظرة سريعة',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text('جدولك الحقيقي، بدون مواعيد مفترضة',
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: violet,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: violet.withValues(alpha: .22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                    color: _stateColor(moment.state),
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Text(moment.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 28),
            const Text('المنبّه القادم',
                style: TextStyle(color: Colors.white70)),
            Text(_time(alarm),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900)),
            Text(_date(alarm),
                style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 26),
        const Text('تفاصيل الدورة',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('${pattern.dutyMinutes ~/ 60}', 'ساعة دوام', coral),
          const SizedBox(width: 9),
          _stat('${pattern.offMinutes ~/ 60}', 'ساعة إجازة', mint),
          const SizedBox(width: 9),
          _stat('${pattern.shifts.length}', 'شِفتات', amber),
        ]),
      ],
    );
  }

  Color _stateColor(ScheduleState state) => switch (state) {
        ScheduleState.work => coral,
        ScheduleState.rest => amber,
        ScheduleState.off => mint,
      };

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 25, fontWeight: FontWeight.w900)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'ص' : 'م'}';
  }
}
