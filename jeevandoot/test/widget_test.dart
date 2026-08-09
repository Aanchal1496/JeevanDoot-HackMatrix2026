import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jeevandoot/main.dart';

void main() {
  testWidgets('App boots through splash to language selection',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const JeevanDootApp());

    // Splash screen is shown first.
    expect(find.text('JeevanDoot'), findsOneWidget);
    expect(find.text('Your health, closer to home.'), findsOneWidget);

    // The splash auto-navigates to the language selection screen.
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pumpAndSettle();

    expect(find.text('JeevanDoot'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
