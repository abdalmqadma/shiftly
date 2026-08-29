import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/main.dart';

void main() {
  testWidgets('Shiftly launches', (tester) async {
    await tester.pumpWidget(const ShiftlyApp());
    expect(find.text('Shiftly'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
