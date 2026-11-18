import 'package:flutter_test/flutter_test.dart';
import 'package:bitify/main.dart';

void main() {
  testWidgets('Bitify app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BitifyApp());
    expect(find.text('Bitify'), findsNothing);
  });
}
