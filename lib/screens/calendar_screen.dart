import 'package:flutter/material.dart';
import '../models/work_pattern.dart';
import '../services/schedule_calculator.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.pattern});
  final WorkPattern pattern;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const violet = Color(0xFF6D4AFF);
  static const coral = Color(0xFFFF6B6B);
  static const mint = Color(0xFF38BFA0);
  static const amber = Color(0xFFFFB84D);
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final calculator = ScheduleCalculator(widget.pattern);
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = (first.weekday + 1) % 7;
    const names = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_right_rounded)),
          Text('${_monthName(month.month)} ${month.year}',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          IconButton(
              onPressed: () =>
                  setState(() => month = DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_left_rounded)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
            children: names
                .map((name) => Expanded(
                    child: Center(
                        child: Text(name,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w800)))))
                .toList()),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 9, crossAxisSpacing: 7),
          itemCount: offset + days,
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final date = DateTime(month.year, month.month, day, 12);
            final state = calculator.stateAt(date).state;
            final today = DateUtils.isSameDay(date, DateTime.now());
            return Container(
              decoration: BoxDecoration(
                color: _color(state).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
                border: today ? Border.all(color: violet, width: 2) : null,
              ),
              child: Center(
                  child: Text('$day',
                      style: TextStyle(
                          fontWeight:
                              today ? FontWeight.w900 : FontWeight.w600))),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(spacing: 18, children: [
          _legend(coral, 'عمل'),
          _legend(amber, 'راحة'),
          _legend(mint, 'إجازة'),
        ]),
      ),
    ]);
  }

  Color _color(ScheduleState state) => switch (state) {
        ScheduleState.work => coral,
        ScheduleState.rest => amber,
        ScheduleState.off => mint,
      };

  Widget _legend(Color color, String text) => Row(mainAxisSize: MainAxisSize.min,
      children: [CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 5), Text(text)]);

  String _monthName(int value) => const [
    'يناير','فبراير','مارس','أبريل','مايو','يونيو',
    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
  ][value - 1];
}
