import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/splash_screen.dart';
import 'package:jeevandoot/services/reminder_notification_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prepare local notifications early so scheduled reminders can fire even
  // if the user hasn't opened the Reminders screen yet.
  await ReminderNotificationService.instance.initialize();
  runApp(const JeevanDootApp());
}

class JeevanDootApp extends StatelessWidget {
  const JeevanDootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeevanDoot',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: const AppScrollBehavior(),
      home: const SplashScreen(),
    );
  }
}