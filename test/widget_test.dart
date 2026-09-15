import 'package:flutter_test/flutter_test.dart';
import 'package:urbanstay/main.dart';

void main() {
  testWidgets('UrbanStay App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbanStayApp());
    expect(find.byType(UrbanStayApp), findsOneWidget);
  });
}
