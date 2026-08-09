import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jeevandoot/main.dart';

void main() {
  testWidgets('App boots to language selection', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JeevanDootApp());

    // The splash screen navigates to the language screen after ~2.2s.
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.text('JeevanDoot'), findsWidgets);
    expect(find.text('Your health, closer to home.'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });
}
