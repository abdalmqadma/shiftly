import 'package:flutter/material.dart';
import '../models/work_pattern.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onSaved});
  final ValueChanged<WorkPattern> onSaved;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _ShiftDraft {
  _ShiftDraft(this.index);
  final int index;
  int startDay = 1;
  int endDay = 1;
  TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay end = const TimeOfDay(hour: 16, minute: 0);
}

class _SetupScreenState extends State<SetupScreen> {
  static const violet = Color(0xFF6D4AFF);
  final _formKey = GlobalKey<FormState>();
  final _dutyController = TextEditingController();
  final _offController = TextEditingController();
  final _countController = TextEditingController();
  final _alarmController = TextEditingController(text: '30');

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  int _step = 0;
  List<_ShiftDraft> _drafts = [];

  @override
  void dispose() {
    _dutyController.dispose();
    _offController.dispose();
    _countController.dispose();
    _alarmController.dispose();
    super.dispose();
  }

  int? _positive(String? value) {
    final number = int.tryParse(value ?? '');
    return number != null && number > 0 ? number : null;
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final count = int.parse(_countController.text);
    setState(() {
      _drafts = List.generate(count, _ShiftDraft.new);
      _step = 1;
    });
  }

  Future<void> _pickTime(_ShiftDraft draft, bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? draft.start : draft.end,
    );
    if (value == null) return;
    setState(() => start ? draft.start = value : draft.end = value);
  }

  int _offset(int day, TimeOfDay time) {
    final cycleStart = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final moment = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day + day - 1,
      time.hour,
      time.minute,
    );
    return moment.difference(cycleStart).inMinutes;
  }

  void _save() {
    final dutyMinutes = int.parse(_dutyController.text) * 60;
    final shifts = <WorkShift>[];

    for (final draft in _drafts) {
      final start = _offset(draft.startDay, draft.start);
      final end = _offset(draft.endDay, draft.end);
      if (start < 0) {
        _error('الشِفت رقم ${draft.index + 1} يبدأ قبل بداية الدورة');
        return;
      }
      if (end <= start) {
        _error('نهاية الشِفت رقم ${draft.index + 1} يجب أن تكون بعد بدايته');
        return;
      }
      if (end > dutyMinutes) {
        _error('الشِفت رقم ${draft.index + 1} يتجاوز مدة الدوام');
        return;
      }
      shifts.add(WorkShift(
        name: 'الشِفت ${draft.index + 1}',
        startOffsetMinutes: start,
        endOffsetMinutes: end,
      ));
    }

    shifts.sort(
        (a, b) => a.startOffsetMinutes.compareTo(b.startOffsetMinutes));
    for (var i = 1; i < shifts.length; i++) {
      if (shifts[i].startOffsetMinutes < shifts[i - 1].endOffsetMinutes) {
        _error('يوجد تداخل بين الشِفتات، راجع الأوقات');
        return;
      }
    }

    widget.onSaved(WorkPattern(
      cycleStart: DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      ),
      dutyMinutes: dutyMinutes,
      offMinutes: int.parse(_offController.text) * 60,
      alarmBeforeMinutes: int.parse(_alarmController.text),
      shifts: shifts,
    ));
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد جدولك',
            style: TextStyle(fontWeight: FontWeight.w900)),
        leading: _step == 1
            ? IconButton(
                onPressed: () => setState(() => _step = 0),
                icon: const Icon(Icons.arrow_forward_rounded))
            : null,
      ),
      body: SafeArea(child: _step == 0 ? _basicStep() : _shiftsStep()),
    );
  }

  Widget _basicStep() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _progress(1, 'بيانات الدورة'),
            const SizedBox(height: 24),
            const Text('كيف يعمل دوامك؟',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('لن نفترض أي مواعيد. أدخل نظامك كما هو.',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: _numberField(
                    _dutyController, 'مدة الدوام', 'بالساعات', Icons.work_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                    _offController, 'مدة الإجازة', 'بالساعات', Icons.home_outlined),
              ),
            ]),
            const SizedBox(height: 14),
            _numberField(_countController, 'كم شِفت تعمل داخل الدورة؟',
                'مثال: 4', Icons.format_list_numbered_rounded),
            const SizedBox(height: 14),
            _numberField(_alarmController, 'التنبيه قبل الشِفت',
                'بالدقائق', Icons.alarm_rounded, allowZero: true),
            const SizedBox(height: 18),
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.event_outlined, color: violet),
                  title: const Text('تاريخ بداية الدورة'),
                  subtitle: Text(_date(_startDate)),
                  onTap: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2045),
                    );
                    if (value != null) setState(() => _startDate = value);
                  },
                ),
                const Divider(height: 1, indent: 18, endIndent: 18),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, color: violet),
                  title: const Text('وقت بداية الدورة'),
                  subtitle: Text(_startTime.format(context)),
                  onTap: () async {
                    final value = await showTimePicker(
                        context: context, initialTime: _startTime);
                    if (value != null) setState(() => _startTime = value);
                  },
                ),
              ]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: violet,
                  minimumSize: const Size.fromHeight(56)),
              onPressed: _continue,
              child: const Text('التالي: مواعيد الشِفتات'),
            ),
          ],
        ),
      );

  Widget _shiftsStep() => ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _progress(2, 'مواعيد الشِفتات'),
          const SizedBox(height: 24),
          const Text('من كم إلى كم؟',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('حدد يوم ووقت بداية ونهاية كل شِفت داخل الدورة.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          ..._drafts.map(_shiftCard),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: violet,
                minimumSize: const Size.fromHeight(56)),
            onPressed: _save,
            child: const Text('حفظ وإنشاء التقويم'),
          ),
        ],
      );

  Widget _shiftCard(_ShiftDraft draft) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('الشِفت ${draft.index + 1}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _dayPicker(draft, true)),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _pickTime(draft, true),
                      child: Text('من ${draft.start.format(context)}'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _dayPicker(draft, false)),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _pickTime(draft, false),
                      child: Text('إلى ${draft.end.format(context)}'))),
            ]),
          ]),
        ),
      );

  Widget _dayPicker(_ShiftDraft draft, bool start) {
    final dutyMinutes = int.parse(_dutyController.text) * 60;
    final startMinute = _startTime.hour * 60 + _startTime.minute;
    final dutyDays = ((startMinute + dutyMinutes + 1439) ~/ 1440)
        .clamp(1, 30);
    final value = start ? draft.startDay : draft.endDay;
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: start ? 'يبدأ في اليوم' : 'ينتهي في اليوم',
        border: const OutlineInputBorder(),
      ),
      items: List.generate(
          dutyDays,
          (index) => DropdownMenuItem(
              value: index + 1, child: Text('اليوم ${index + 1}'))),
      onChanged: (selected) {
        if (selected == null) return;
        setState(() =>
            start ? draft.startDay = selected : draft.endDay = selected);
      },
    );
  }

  Widget _numberField(TextEditingController controller, String label,
          String hint, IconData icon,
          {bool allowZero = false}) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
        validator: (value) {
          final number = int.tryParse(value ?? '');
          if (number == null || (allowZero ? number < 0 : number <= 0)) {
            return 'أدخل رقمًا صحيحًا';
          }
          if (identical(controller, _countController) && number > 20) {
            return 'الحد الأقصى لعدد الشِفتات هو 20';
          }
          return null;
        },
      );

  Widget _progress(int number, String title) => Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration:
              const BoxDecoration(color: violet, shape: BoxShape.circle),
          child: Center(
              child: Text('$number/2',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]);

  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
