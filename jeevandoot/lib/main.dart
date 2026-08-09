import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/splash_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';

void main() {
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
