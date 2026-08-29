import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/main.dart';

void main() {
  testWidgets('Shiftly opens with an empty setup state', (tester) async {
    await tester.pumpWidget(const ShiftlyApp());
    expect(find.text('Shiftly'), findsOneWidget);
    expect(find.text('ابدأ بإنشاء جدولك'), findsOneWidget);
    expect(find.text('إنشاء أول دورة'), findsOneWidget);
  });
}
