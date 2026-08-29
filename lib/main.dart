import 'package:flutter/material.dart';

void main() => runApp(const ShiftlyApp());

class ShiftlyApp extends StatelessWidget {
  const ShiftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF3867D6);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shiftly',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFF7F8FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const ShiftlyHome(),
    );
  }
}

enum ShiftKind { work, rest, off }

class ShiftBlock {
  const ShiftBlock(this.startHour, this.endHour, this.kind, this.title);
  final int startHour;
  final int endHour;
  final ShiftKind kind;
  final String title;
}

class ShiftlyHome extends StatefulWidget {
  const ShiftlyHome({super.key});

  @override
  State<ShiftlyHome> createState() => _ShiftlyHomeState();
}

class _ShiftlyHomeState extends State<ShiftlyHome> {
  int _tab = 0;
  DateTime _cycleStart = DateTime(2026, 8, 30, 10);
  int _alarmBefore = 30;
  DateTime _shownMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const _blocks = <ShiftBlock>[
    ShiftBlock(0, 6, ShiftKind.rest, 'راحة'),
    ShiftBlock(6, 12, ShiftKind.work, 'عمل'),
    ShiftBlock(12, 18, ShiftKind.rest, 'راحة'),
    ShiftBlock(18, 36, ShiftKind.work, 'عمل'),
    ShiftBlock(36, 42, ShiftKind.rest, 'راحة'),
    ShiftBlock(42, 48, ShiftKind.work, 'عمل'),
    ShiftBlock(48, 72, ShiftKind.off, 'إجازة'),
  ];

  Color _color(ShiftKind kind) => switch (kind) {
        ShiftKind.work => const Color(0xFFFF8A65),
        ShiftKind.rest => const Color(0xFF64B5F6),
        ShiftKind.off => const Color(0xFF66BB8A),
      };

  String _kindName(ShiftKind kind) => switch (kind) {
        ShiftKind.work => 'عمل',
        ShiftKind.rest => 'راحة في الموقع',
        ShiftKind.off => 'إجازة',
      };

  ShiftKind _kindAt(DateTime date) {
    final hours = date.difference(_cycleStart).inMinutes / 60;
    final cycleHour = ((hours % 72) + 72) % 72;
    return _blocks
        .firstWhere((b) => cycleHour >= b.startHour && cycleHour < b.endHour)
        .kind;
  }

  DateTime _nextWorkStart(DateTime from) {
    for (var cycle = -1; cycle < 400; cycle++) {
      final base = _cycleStart.add(Duration(hours: cycle * 72));
      for (final block in _blocks.where((b) => b.kind == ShiftKind.work)) {
        final start = base.add(Duration(hours: block.startHour));
        if (start.isAfter(from)) return start;
      }
    }
    return from;
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _calendar(), _settings()];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shiftly', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: () {},
              icon: const Badge(child: Icon(Icons.notifications_none_rounded)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(child: pages[_tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'التقويم'),
            NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'الإعدادات'),
          ],
        ),
        floatingActionButton: _tab == 1
            ? FloatingActionButton.extended(
                onPressed: _showManualAlarm,
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text('منبّه يدوي'),
              )
            : null,
      ),
    );
  }

  Widget _dashboard() {
    final now = DateTime.now();
    final kind = _kindAt(now);
    final nextWork = _nextWorkStart(now);
    final alarm = nextWork.subtract(Duration(minutes: _alarmBefore));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('أهلًا عبد الهادي', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('جدول مناوباتك محسوب تلقائيًا', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3867D6), Color(0xFF5B8DEF)]),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('حالتك الآن', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _color(kind), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(_kindName(kind), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 26),
              const Text('المنبّه القادم', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('${_date(alarm)} • ${_time(alarm)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('قبل بداية العمل بـ $_alarmBefore دقيقة', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('الدورة الحالية', action: 'تعديل', onTap: _showSetup),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _infoRow(Icons.play_circle_outline, 'بداية الدورة', '${_date(_cycleStart)} • ${_time(_cycleStart)}'),
                const Divider(height: 28),
                _infoRow(Icons.sync_rounded, 'نظام المناوبة', '48 ساعة دوام + 24 ساعة إجازة'),
                const Divider(height: 28),
                _infoRow(Icons.alarm_rounded, 'التنبيه', 'قبل العمل بـ $_alarmBefore دقيقة'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('دليل الألوان'),
        const SizedBox(height: 10),
        Row(
          children: ShiftKind.values
              .map((kind) => Expanded(
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _color(kind).withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                      child: Column(children: [
                        CircleAvatar(radius: 6, backgroundColor: _color(kind)),
                        const SizedBox(height: 6),
                        Text(_kindName(kind), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _calendar() {
    final first = DateTime(_shownMonth.year, _shownMonth.month, 1);
    final days = DateTime(_shownMonth.year, _shownMonth.month + 1, 0).day;
    final offset = (first.weekday + 1) % 7;
    const week = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => setState(() => _shownMonth = DateTime(_shownMonth.year, _shownMonth.month - 1)), icon: const Icon(Icons.chevron_right)),
              Text('${_monthName(_shownMonth.month)} ${_shownMonth.year}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => setState(() => _shownMonth = DateTime(_shownMonth.year, _shownMonth.month + 1)), icon: const Icon(Icons.chevron_left)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: week.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700))))).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 6),
            itemCount: offset + days,
            itemBuilder: (_, index) {
              if (index < offset) return const SizedBox();
              final day = index - offset + 1;
              final date = DateTime(_shownMonth.year, _shownMonth.month, day, 12);
              final kind = _kindAt(date);
              final today = DateUtils.isSameDay(date, DateTime.now());
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDay(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: _color(kind).withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(12),
                    border: today ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                  ),
                  child: Center(child: Text('$day', style: TextStyle(fontWeight: today ? FontWeight.w900 : FontWeight.w600))),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _settings() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('إعدادات Shiftly', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _settingsTile(Icons.work_history_outlined, 'إعداد دورة العمل', 'تاريخ البداية وفترات العمل والراحة', _showSetup),
          _settingsTile(Icons.alarm_outlined, 'إعدادات المنبّه', 'التنبيه قبل العمل بـ $_alarmBefore دقيقة', _showSetup),
          _settingsTile(Icons.extension_outlined, 'تحدي إيقاف المنبّه', 'مسائل حسابية • قريبًا', () {}),
          _settingsTile(Icons.auto_awesome_outlined, 'إدخال الجدول بالذكاء الاصطناعي', 'اربط وصفك بجدول تلقائي • قريبًا', () {}),
        ],
      );

  Widget _sectionTitle(String title, {String? action, VoidCallback? onTap}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (action != null) TextButton(onPressed: onTap, child: Text(action)),
        ],
      );

  Widget _infoRow(IconData icon, String title, String value) => Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFFEAF0FF), child: Icon(icon, color: const Color(0xFF3867D6))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ])),
        ],
      );

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(backgroundColor: const Color(0xFFEAF0FF), child: Icon(icon, color: const Color(0xFF3867D6))),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left),
          onTap: onTap,
        ),
      );

  String _monthName(int month) => const ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'][month - 1];

  Future<void> _showSetup() async {
    var date = _cycleStart;
    var lead = _alarmBefore.toDouble();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('إعداد دورة المناوبة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('أول يوم في الدورة'),
                subtitle: Text('${_date(date)} • ${_time(date)}'),
                onTap: () async {
                  final chosen = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2040));
                  if (chosen != null) setSheetState(() => date = DateTime(chosen.year, chosen.month, chosen.day, date.hour, date.minute));
                },
              ),
              const SizedBox(height: 8),
              Text('التنبيه قبل العمل: ${lead.round()} دقيقة', style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(value: lead, min: 0, max: 120, divisions: 24, label: '${lead.round()}', onChanged: (value) => setSheetState(() => lead = value)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _cycleStart = date;
                    _alarmBefore = lead.round();
                  });
                  Navigator.pop(sheetContext);
                },
                child: const Text('حفظ وإنشاء التقويم'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDay(DateTime date) {
    final kind = _kindAt(date);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_date(date), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('الحالة: ${_kindName(kind)}'),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: () { Navigator.pop(context); _showManualAlarm(); }, icon: const Icon(Icons.alarm_add), label: const Text('إضافة منبّه لهذا اليوم')),
          ]),
        ),
      ),
    );
  }

  void _showManualAlarm() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إضافة المنبّه اليدوي ستكتمل في الخطوة القادمة')));
  }
}
