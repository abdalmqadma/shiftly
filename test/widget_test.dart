import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Shiftly starts as a wake-up alarm app', (tester) async {
    await tester.pumpWidget(const ShiftlyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('منبّهاتك'), findsOneWidget);
    expect(find.text('الشفتات'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
