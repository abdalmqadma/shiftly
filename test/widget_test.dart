import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';

void main() {
  testWidgets('Shiftly starts as a wake-up alarm app', (tester) async {
    await tester.pumpWidget(const ShiftlyApp());
    await tester.pumpAndSettle();

    expect(find.text('منبّهاتك'), findsOneWidget);
    expect(find.text('الشفتات'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
