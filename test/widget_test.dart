import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';

void main() {
  testWidgets('Shiftly starts with schedule setup', (tester) async {
    await tester.pumpWidget(const ShiftlyApp());
    expect(find.text('كيف يعمل دوامك؟'), findsOneWidget);
    expect(find.text('التالي: مواعيد الشِفتات'), findsOneWidget);
  });
}
