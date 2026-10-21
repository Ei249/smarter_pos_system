import 'package:flutter_test/flutter_test.dart';
import 'package:hr_app/main.dart';

void main() {
  testWidgets('HR App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HRApp());
  });
}