import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/splash_screen.dart';
import 'package:jeevandoot/services/sync_queue.dart';
import 'package:jeevandoot/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SyncQueue.instance.init();
  await AppStrings.load();
  runApp(const JeevanDootApp());
}

class JeevanDootApp extends StatelessWidget {
  const JeevanDootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppStrings.language,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'JeevanDoot',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          scrollBehavior: const AppScrollBehavior(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
