import 'package:flutter/material.dart';
import '../models/work_pattern.dart';
import '../services/alarm_service.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.pattern,
    required this.onEditPattern,
  });

  final WorkPattern pattern;
  final VoidCallback onEditPattern;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int page = 0;
  static const violet = Color(0xFF6D4AFF);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(pattern: widget.pattern),
      CalendarScreen(pattern: widget.pattern),
      _settings(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: violet, borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.timelapse_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          const Text('Shiftly',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        ]),
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(child: pages[page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined), label: 'اليوم'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined), label: 'جدولي'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'الإعدادات'),
        ],
      ),
    );
  }

  Widget _settings() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('الإعدادات',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: const Icon(Icons.edit_calendar_rounded, color: violet),
          title: const Text('تعديل نظام المناوبة',
              style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
              '${widget.pattern.shifts.length} شِفتات داخل دورة مدتها ${widget.pattern.cycleMinutes ~/ 60} ساعة'),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: widget.onEditPattern,
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: const Icon(Icons.alarm_on_rounded, color: violet),
          title: const Text('اختبار المنبّه',
              style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('يرن بعد دقيقة ويطلب تحدي الحساب'),
          trailing: const Icon(Icons.play_arrow_rounded),
          onTap: () async {
            await AlarmService.scheduleTestAlarm();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم ضبط الاختبار بعد دقيقة')),
            );
          },
        ),
      ),
    ],
  );
}
