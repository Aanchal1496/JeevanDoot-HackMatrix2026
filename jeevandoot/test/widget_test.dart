import 'package:flutter_test/flutter_test.dart';

import 'package:jeevandoot/main.dart';

void main() {
  testWidgets('App boots to language selection', (WidgetTester tester) async {
    await tester.pumpWidget(const JeevanDootApp());

    expect(find.text('JeevanDoot'), findsOneWidget);
    expect(find.text('Your health, closer to home.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
