import 'dart:math';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

class AlarmChallengeScreen extends StatefulWidget {
  const AlarmChallengeScreen({
    super.key,
    required this.alarmId,
    required this.onCompleted,
  });

  final int alarmId;
  final VoidCallback onCompleted;

  @override
  State<AlarmChallengeScreen> createState() => _AlarmChallengeScreenState();
}

class _AlarmChallengeScreenState extends State<AlarmChallengeScreen> {
  static const violet = Color(0xFF6D4AFF);
  final controller = TextEditingController();
  late int first;
  late int second;
  int solved = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    final random = Random();
    first = 8 + random.nextInt(42);
    second = 3 + random.nextInt(27);
  }

  Future<void> _submit() async {
    final answer = int.tryParse(controller.text.trim());
    if (answer != first + second) {
      setState(() => error = 'الإجابة غير صحيحة، حاول مرة ثانية');
      controller.clear();
      return;
    }

    if (solved < 2) {
      setState(() {
        solved++;
        error = null;
        controller.clear();
        _newQuestion();
      });
      return;
    }

    await Alarm.stop(widget.alarmId);
    widget.onCompleted();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF211B38),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: violet.withValues(alpha: .22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.alarm_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                const Text('اصحى، موعدك اقترب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('أكمل 3 مسائل لإيقاف المنبّه • ${solved + 1}/3',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(children: [
                    Text('$first + $second = ؟',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                            fontSize: 38, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'اكتب الإجابة',
                        errorText: error,
                        filled: true,
                        fillColor: const Color(0xFFF5F2FF),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: violet,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      onPressed: _submit,
                      child: Text(solved == 2 ? 'حل وإيقاف المنبّه' : 'التالي'),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('لا يمكن إيقاف الصوت قبل إكمال التحدي',
                    style: TextStyle(color: Colors.white54)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
