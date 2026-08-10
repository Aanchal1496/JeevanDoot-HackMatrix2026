import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/home_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

class AppointmentConfirmationScreen extends StatefulWidget {
  const AppointmentConfirmationScreen({
    super.key,
    this.type = 'audio',
    this.time = '5:30 PM',
    this.date = 'August 10, 2026',
    this.weekday = 'Monday',
  });

  final String type;
  final String time;
  final String date;
  final String weekday;

  @override
  State<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState
    extends State<AppointmentConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _particles = List.generate(
      50,
      (_) => _ConfettiParticle(
        x: _random.nextDouble(),
        y: 0.3 + _random.nextDouble() * 0.1,
        dx: (_random.nextDouble() - 0.5) * 0.02,
        dy: -0.02 - _random.nextDouble() * 0.02,
        radius: 2 + _random.nextDouble() * 4,
        color: _colors[_random.nextInt(_colors.length)],
      ),
    );
  }

  static const List<Color> _colors = [
    Color(0xFF006B5E),
    Color(0xFF5BDAC6),
    Color(0xFF7AF7E1),
    Color(0xFFC38800),
    Color(0xFFFFBA38),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _backToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAudio = widget.type == 'audio';
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  _particles,
                  _controller.value,
                ),
              );
            },
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _successIllustration(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text(
                      AppStrings.tr('Appointment Confirmed'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayHeroMobile
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      AppStrings.tr('Your consultation has been successfully scheduled.'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _detailsCard(scheme, isAudio),
                    const SizedBox(height: AppSpacing.stackLg),
                    PillButton(
                      label: AppStrings.tr('View Appointment'),
                      icon: Icons.receipt_long,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppStrings.tr('Appointment added to your Records.')),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    TextButton(
                      onPressed: _backToHome,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                        textStyle: AppTextStyles.labelLg,
                      ),
                      child: Text(AppStrings.tr('Back to Home')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successIllustration(ColorScheme scheme) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(ColorScheme scheme, bool isAudio) {
    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ColoredBox(
                    color: scheme.surfaceContainerHigh,
                    child: const Icon(Icons.person, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('Dr. Priya Sharma'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      AppStrings.tr('General Physician'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
            child: Divider(color: scheme.surfaceContainerHighest),
          ),
          _detailRow(scheme, Icons.calendar_today, widget.date, widget.weekday),
          const SizedBox(height: AppSpacing.stackSm),
          _detailRow(scheme, Icons.schedule, widget.time, AppStrings.tr('15 min duration')),
          const SizedBox(height: AppSpacing.stackSm),
          _detailRow(
            scheme,
            isAudio ? Icons.mic : Icons.videocam,
            isAudio ? AppStrings.tr('Audio Consultation') : AppStrings.tr('Video Consultation'),
            isAudio
                ? AppStrings.tr('We will call you on your registered number.')
                : AppStrings.tr('Join from the app at the scheduled time.'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(ColorScheme scheme, IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.secondary, size: 20),
        const SizedBox(width: AppSpacing.unit),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.radius,
    required this.color,
  });

  double x;
  double y;
  final double dx;
  final double dy;
  final double radius;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.progress);

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.08) return;
    final t = (progress - 0.08) / 0.92;
    final paint = Paint();
    for (final p in particles) {
      final localT = t;
      final x = (p.x + p.dx * localT * 100) * size.width;
      final y = p.y * size.height + p.dy * localT * 600 + 0.5 * 98 * localT * localT;
      if (y > size.height) continue;
      paint.color = p.color;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
