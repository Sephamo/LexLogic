import 'package:flutter_test/flutter_test.dart';
import 'package:policy_app/main.dart';

void main() {
  testWidgets('PolicyChecker app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PolicyApp());

    expect(find.byType(PolicyApp), findsOneWidget);
  });
}
