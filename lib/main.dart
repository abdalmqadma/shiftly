import 'package:flutter/material.dart';

void main() => runApp(const ShiftlyApp());

class ShiftlyApp extends StatelessWidget {
  const ShiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6D4AFF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF7),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFEDE8FF),
          height: 72,
        ),
      ),
      home: const ShiftlyHome(),
    );
  }
}

enum ShiftKind { work, rest, off }

class ShiftPart {
  const ShiftPart(this.startHour, this.endHour, this.kind);
  final int startHour;
  final int endHour;
  final ShiftKind kind;
}

class ShiftlyHome extends StatefulWidget {
  const ShiftlyHome({super.key});

  @override
  State<ShiftlyHome> createState() => _ShiftlyHomeState();
}

class _ShiftlyHomeState extends State<ShiftlyHome> {
  static const violet = Color(0xFF6D4AFF);
  static const coral = Color(0xFFFF6B6B);
  static const mint = Color(0xFF38BFA0);
  static const amber = Color(0xFFFFB84D);

  static const _parts = [
    ShiftPart(0, 6, ShiftKind.rest),
    ShiftPart(6, 12, ShiftKind.work),
    ShiftPart(12, 18, ShiftKind.rest),
    ShiftPart(18, 36, ShiftKind.work),
    ShiftPart(36, 42, ShiftKind.rest),
    ShiftPart(42, 48, ShiftKind.work),
    ShiftPart(48, 72, ShiftKind.off),
  ];

  int _page = 0;
  DateTime? _cycleStart;
  int _alarmBefore = 30;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  Color _color(ShiftKind kind) => switch (kind) {
        ShiftKind.work => coral,
        ShiftKind.rest => amber,
        ShiftKind.off => mint,
      };

  String _label(ShiftKind kind) => switch (kind) {
        ShiftKind.work => 'عمل',
        ShiftKind.rest => 'راحة',
        ShiftKind.off => 'إجازة',
      };

  ShiftKind _kindAt(DateTime date) {
    final start = _cycleStart!;
    final hours = date.difference(start).inMinutes / 60;
    final cycleHour = ((hours % 72) + 72) % 72;
    return _parts
        .firstWhere((part) =>
            cycleHour >= part.startHour && cycleHour < part.endHour)
        .kind;
  }

  DateTime _nextWork(DateTime from) {
    final start = _cycleStart!;
    for (var cycle = -1; cycle < 400; cycle++) {
      final base = start.add(Duration(hours: cycle * 72));
      for (final part in _parts.where((part) => part.kind == ShiftKind.work)) {
        final time = base.add(Duration(hours: part.startHour));
        if (time.isAfter(from)) return time;
      }
    }
    return from;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_home(), _calendar(), _settings()];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          titleSpacing: 22,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: violet,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.timelapse_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 10),
              const Text('Shiftly',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(child: screens[_page]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _page,
          onDestinationSelected: (value) => setState(() => _page = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'اليوم'),
            NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'جدولي'),
            NavigationDestination(
                icon: Icon(Icons.tune_rounded), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  Widget _home() {
    if (_cycleStart == null) return _emptyHome();

    final now = DateTime.now();
    final current = _kindAt(now);
    final work = _nextWork(now);
    final alarm = work.subtract(Duration(minutes: _alarmBefore));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text('نظرة سريعة',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text('كل ما تحتاجه قبل مناوبتك القادمة',
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: violet,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: violet.withValues(alpha: .24),
                  blurRadius: 30,
                  offset: const Offset(0, 14)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: _color(current), shape: BoxShape.circle)),
                const SizedBox(width: 9),
                Text('أنت الآن في فترة ${_label(current)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 28),
              const Text('المنبّه القادم',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(_time(alarm),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900)),
              Text(_date(alarm),
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const Text('دورتك',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(children: [
          _stat('48', 'ساعة دوام', coral),
          const SizedBox(width: 10),
          _stat('24', 'ساعة إجازة', mint),
          const SizedBox(width: 10),
          _stat('$_alarmBefore', 'دقيقة قبلها', amber),
        ]),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _setup,
          icon: const Icon(Icons.edit_calendar_outlined),
          label: const Text('تعديل دورة المناوبة'),
        ),
      ],
    );
  }

  Widget _emptyHome() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  size: 72, color: violet),
            ),
            const SizedBox(height: 30),
            const Text('ابدأ بإنشاء جدولك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'أدخل بداية دورة مناوبتك مرة واحدة، وسنرتب التقويم والمنبّهات تلقائيًا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: violet),
              onPressed: _setup,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إنشاء أول دورة'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _comingSoon('الإدخال الذكي'),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('اكتب جدولي بالذكاء الاصطناعي'),
            ),
          ]),
        ),
      );

  Widget _calendar() {
    if (_cycleStart == null) {
      return _emptySection(
          Icons.event_busy_outlined,
          'التقويم فارغ',
          'أنشئ دورة مناوبة لتظهر أيام العمل والراحة هنا.',
          _setup);
    }

    final first = DateTime(_month.year, _month.month, 1);
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = (first.weekday + 1) % 7;
    const weekdays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1)),
              icon: const Icon(Icons.chevron_right_rounded)),
          Text('${_monthName(_month.month)} ${_month.year}',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_left_rounded)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
            children: weekdays
                .map((day) => Expanded(
                    child: Center(
                        child: Text(day,
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
          itemCount: offset + count,
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final date = DateTime(_month.year, _month.month, day, 12);
            final kind = _kindAt(date);
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            return Container(
              decoration: BoxDecoration(
                color: _color(kind).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
                border: isToday ? Border.all(color: violet, width: 2) : null,
              ),
              child: Center(
                  child: Text('$day',
                      style: TextStyle(
                          fontWeight:
                              isToday ? FontWeight.w900 : FontWeight.w600))),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ShiftKind.values
                .map((kind) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 5, backgroundColor: _color(kind)),
                        const SizedBox(width: 5),
                        Text(_label(kind))
                      ]),
                    ))
                .toList()),
      ),
    ]);
  }

  Widget _settings() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('الإعدادات',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          _tile(Icons.repeat_rounded, 'دورة المناوبة',
              _cycleStart == null ? 'لم يتم إعدادها' : '48 عمل • 24 إجازة',
              _setup),
          _tile(Icons.alarm_rounded, 'المنبّهات',
              'قبل بداية العمل بـ $_alarmBefore دقيقة',
              _cycleStart == null ? _setup : _setup),
          _tile(Icons.extension_rounded, 'تحدي الاستيقاظ',
              'مسائل حسابية وكتابة جملة',
              () => _comingSoon('تحدي الاستيقاظ')),
          _tile(Icons.auto_awesome_rounded, 'الإدخال الذكي',
              'حوّل وصف دوامك إلى جدول',
              () => _comingSoon('الإدخال الذكي')),
        ],
      );

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 25, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback tap) =>
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFFEDE8FF),
                borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: violet),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
          onTap: tap,
        ),
      );

  Widget _emptySection(
          IconData icon, String title, String body, VoidCallback action) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 70, color: violet),
            const SizedBox(height: 18),
            Text(title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 22),
            FilledButton(
                onPressed: action, child: const Text('إعداد المناوبة')),
          ]),
        ),
      );

  Future<void> _setup() async {
    var date = _cycleStart ?? DateTime.now();
    var lead = _alarmBefore.toDouble();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF7),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                22, 18, 22, MediaQuery.viewInsetsOf(context).bottom + 26),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                      child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text('إعداد مناوبتك',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('النظام الحالي: 48 ساعة دوام ثم 24 ساعة إجازة',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined, color: violet),
                    title: const Text('تاريخ بداية الدورة'),
                    subtitle: Text(_date(date)),
                    onTap: () async {
                      final selected = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2045));
                      if (selected != null) {
                        updateSheet(() => date = DateTime(selected.year,
                            selected.month, selected.day, date.hour, date.minute));
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded, color: violet),
                    title: const Text('وقت بداية الدورة'),
                    subtitle: Text(_time(date)),
                    onTap: () async {
                      final selected = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(date));
                      if (selected != null) {
                        updateSheet(() => date = DateTime(date.year, date.month,
                            date.day, selected.hour, selected.minute));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('نبّهني قبل العمل بـ ${lead.round()} دقيقة',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Slider(
                      value: lead,
                      min: 0,
                      max: 120,
                      divisions: 24,
                      activeColor: violet,
                      onChanged: (value) => updateSheet(() => lead = value)),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: violet,
                        minimumSize: const Size.fromHeight(54)),
                    onPressed: () {
                      setState(() {
                        _cycleStart = date;
                        _alarmBefore = lead.round();
                      });
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('إنشاء الجدول'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$feature ستكون في الخطوة القادمة')));
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour < 12 ? 'ص' : 'م'}';
  }

  String _monthName(int month) => const [
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
        'ديسمبر'
      ][month - 1];
}
