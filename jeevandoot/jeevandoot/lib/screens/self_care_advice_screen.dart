import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/book_consultation_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class SelfCareAdviceScreen extends StatelessWidget {
  const SelfCareAdviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackSm,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Take care of yourself',
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Simple steps to help you feel better and recover comfortably at home.',
              style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            const _AdviceCard(
              title: 'Hydration',
              icon: Icons.water_drop,
              body:
                  'Drink enough water. Keep a bottle nearby and take small sips regularly throughout the day.',
            ),
            const SizedBox(height: AppSpacing.gutter),
            const _AdviceCard(
              title: 'Rest',
              icon: Icons.bedtime,
              body:
                  'Get plenty of rest. Allow your body the time it needs to heal in a quiet, comfortable space.',
            ),
            const SizedBox(height: AppSpacing.gutter),
            const _AdviceCard(
              title: 'Monitor',
              icon: Icons.thermostat,
              body:
                  'Keep track of your temperature. Note any changes and record them in your daily log.',
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Need help?',
                    style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'If your symptoms worsen or you feel uneasy, we are here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  PillButton(
                    label: 'Talk to a Doctor',
                    icon: Icons.medical_services,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primaryContainer, size: 24),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            body,
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
