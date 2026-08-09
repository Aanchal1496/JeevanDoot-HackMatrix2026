import 'package:flutter/material.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/triage_result_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key, required this.selectedSymptoms});

  final Set<String> selectedSymptoms;

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const List<double> _baseHeights = [0.3, 0.8, 0.5, 0.9, 0.6, 1.0, 0.7, 0.4];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    TriageResult? result;
    try {
      result = await runTriage(widget.selectedSymptoms.toList());
    } catch (_) {
      // Fall back to the local rule engine so the flow still completes.
      final localLevel = computeTriage(widget.selectedSymptoms);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TriageResultScreen(level: localLevel),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TriageResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: scheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  120,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'Listening...',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLgMobile.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _micRipple(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    _waveform(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    _transcription(scheme),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      "Tap the microphone when you're done.",
                      style: AppTextStyles.labelLg.copyWith(color: scheme.secondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.gutter,
          AppSpacing.containerMargin,
          16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface.withValues(alpha: 0),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: PillButton(
                  label: _busy ? 'Analyzing…' : 'Done',
                  icon: Icons.check,
                  loading: _busy,
                  onPressed: _finish,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              Expanded(
                child: PillButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.onSurface,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _micRipple(ColorScheme scheme) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final delay in const [Duration.zero, Duration(milliseconds: 500), Duration(milliseconds: 1000)])
            _RippleCircle(
              color: scheme.primaryContainer,
              controller: _controller,
              delay: delay,
            ),
          InkWell(
            onTap: _finish,
            customBorder: const CircleBorder(),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.mic, size: 40, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waveform(ColorScheme scheme) {
    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _baseHeights.length; i++)
                _waveBar(scheme, i),
            ],
          );
        },
      ),
    );
  }

  Widget _waveBar(ColorScheme scheme, int index) {
    final progress = _controller.value;
    final phase = (index * 0.7 + progress * 2) % 1.0;
    final height = (_baseHeights[index] * 0.4 + 0.6 * phase) * 64;
    return Container(
      width: 8,
      height: height.clamp(8, 64),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(999)),
      ),
    );
  }

  Widget _transcription(ColorScheme scheme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '"Mujhe do din se bukhar hai..."',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLg.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class _RippleCircle extends StatelessWidget {
  const _RippleCircle({
    required this.color,
    required this.controller,
    required this.delay,
  });

  final Color color;
  final Animation<double> controller;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = ((controller.value * 1000 - delay.inMilliseconds) % 1000) / 1000;
        final scale = 1.0 + t * 0.9;
        final opacity = (1 - t) * 0.5;
        return Container(
          width: 192,
          height: 192,
          transform: Matrix4.diagonal3Values(scale, scale, 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
