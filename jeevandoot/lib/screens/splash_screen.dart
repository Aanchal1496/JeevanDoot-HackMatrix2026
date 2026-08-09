import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/doctor/doctor_home_screen.dart';
import 'package:jeevandoot/screens/home_screen.dart';
import 'package:jeevandoot/screens/language_selection_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';

/// Launch splash shown briefly before the language selection screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final role = await sessionRole();
    if (!mounted) return;
    if (role != null) {
      await restoreSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => role == 'doctor'
              ? const DoctorHomeScreen()
              : const HomeScreen(),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceBright,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    size: 52,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'JeevanDoot',
                  style: AppTextStyles.displayHero.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'Your health, closer to home.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
