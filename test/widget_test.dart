import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_123pan/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Pan123App());
    await tester.pump();
    expect(find.byType(Pan123App), findsOneWidget);
  });
}
