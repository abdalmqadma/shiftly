import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TimeWheelPicker extends StatelessWidget {
  const TimeWheelPicker({
    super.key,
    required this.hourController,
    required this.minuteController,
    required this.periodController,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
  });

  final FixedExtentScrollController hourController;
  final FixedExtentScrollController minuteController;
  final FixedExtentScrollController periodController;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: .18),
        ),
      ),
      child: Column(
        children: [
          Text(
            'اسحب للأعلى أو للأسفل لتحديد الوقت',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                        color: Colors.black.withValues(alpha: .08),
                      ),
                    ],
                  ),
                ),
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: _wheel(
                        controller: hourController,
                        count: 12,
                        valueBuilder: (index) =>
                            '${index + 1}'.padLeft(2, '0'),
                        onChanged: onHourChanged,
                      ),
                    ),
                    const Text(':',
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w900)),
                    Expanded(
                      child: _wheel(
                        controller: minuteController,
                        count: 60,
                        valueBuilder: (index) => '$index'.padLeft(2, '0'),
                        onChanged: onMinuteChanged,
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: _wheel(
                        controller: periodController,
                        count: 2,
                        valueBuilder: (index) => index == 0 ? 'ص' : 'م',
                        onChanged: onPeriodChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int index) valueBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 52,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.35,
      perspective: 0.003,
      squeeze: 0.95,
      overAndUnderCenterOpacity: .28,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          if (index == null) return null;
          return Center(
            child: Text(
              valueBuilder(index),
              style: const TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          );
        },
      ),
    );
  }
}
