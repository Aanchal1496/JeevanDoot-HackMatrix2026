import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jeevandoot/main.dart';

void main() {
  testWidgets('App boots to language selection', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JeevanDootApp());

    // Splash screen is shown first.
    expect(find.text('JeevanDoot'), findsWidgets);
    expect(find.text('Your health, closer to home.'), findsWidgets);

    // Advance past the splash delay so the language selection screen appears.
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 400));

    // Language selection is now visible with its primary CTA.
    expect(find.text('Continue'), findsOneWidget);
  });
}
