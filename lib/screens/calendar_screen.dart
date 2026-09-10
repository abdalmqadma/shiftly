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

    const dayNames = ['سبت', 'أحد', 'اثن', 'ثلا', 'أرب', 'خمي', 'جمع'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التقويم',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: .45),
                ),
              ),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        _monthButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'الشهر السابق',
                          onPressed: _previousMonth,
                        ),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              '${_monthName(month.month)} ${month.year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        _monthButton(
                          icon: Icons.chevron_right_rounded,
                          tooltip: 'الشهر التالي',
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: dayNames
                          .map(
                            (name) => Expanded(
                              child: Center(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 6,
                        childAspectRatio: .92,
                      ),
                      itemCount: offset + days,
                      itemBuilder: (_, index) {
                        if (index < offset) return const SizedBox();

                        final day = index - offset + 1;
                        final date = DateTime(month.year, month.month, day, 12);
                        final state = calculator.stateAt(date).state;
                        final isToday =
                            DateUtils.isSameDay(date, DateTime.now());

                        return _dayCell(
                          day: day,
                          state: state,
                          isToday: isToday,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 22,
                  runSpacing: 10,
                  children: [
                    _legend(coral, 'عمل'),
                    _legend(amber, 'راحة'),
                    _legend(mint, 'إجازة'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: const Color(0xFFF3F0FF),
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: violet),
      ),
    );
  }

  Widget _dayCell({
    required int day,
    required ScheduleState state,
    required bool isToday,
  }) {
    final stateColor = _color(state);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isToday ? violet : stateColor.withValues(alpha: .20),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() => month = DateTime(month.year, month.month - 1));
  }

  void _nextMonth() {
    setState(() => month = DateTime(month.year, month.month + 1));
  }

  Color _color(ScheduleState state) => switch (state) {
        ScheduleState.work => coral,
        ScheduleState.rest => amber,
        ScheduleState.off => mint,
      };

  Widget _legend(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );

  String _monthName(int value) => const [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ][value - 1];
}
