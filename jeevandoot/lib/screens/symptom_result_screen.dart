import 'package:flutter/material.dart';

import '../models/symptom_result.dart';
import '../screens/book_consultation_screen.dart';
import '../screens/self_care_advice_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import '../widgets/risk_result_card.dart';

/// Step 3 of the symptom checker: the backend risk assessment.
class SymptomResultScreen extends StatelessWidget {
  const SymptomResultScreen({super.key, required this.result});

  final SymptomResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isHigh = result.riskLevel == 'HIGH';
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        leadingIcon: Icons.close,
        title: 'JeevanDoot',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Symptom Check',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (isHigh) ...[
              _emergencyBanner(scheme),
              const SizedBox(height: AppSpacing.stackMd),
            ],
            RiskResultCard(result: result),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              result.summary,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _section(scheme, 'What we detected', Icons.search, children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in result.symptoms)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.labelLg.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              if (result.symptoms.isEmpty)
                Text(
                  'No specific symptoms were identified.',
                  style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
            ]),
            const SizedBox(height: AppSpacing.stackSm),
            _section(scheme, 'Why this risk level?', Icons.info_outline, children: [
              Text(
                result.explanation,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: AppSpacing.stackSm),
            if (result.precautions.isNotEmpty)
              _section(scheme, 'What you can do', Icons.tips_and_updates_outlined,
                  children: [
                    for (final p in result.precautions)
                      _bullet(scheme, p, Icons.check_circle_outline, scheme.primary),
                  ]),
            if (result.precautions.isEmpty && !isHigh)
              _section(scheme, 'What you can do', Icons.tips_and_updates_outlined,
                  children: [
                    _bullet(scheme, 'Rest and stay hydrated.', Icons.check_circle_outline, scheme.primary),
                    _bullet(scheme, 'Monitor how you feel.', Icons.check_circle_outline, scheme.primary),
                  ]),
            if (result.warningSigns.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackSm),
              _section(scheme, 'When to seek help', Icons.health_and_safety,
                  children: [
                    for (final w in result.warningSigns)
                      _bullet(scheme, w, Icons.warning_amber_rounded, scheme.tertiary),
                  ]),
            ],
            if (result.seekMedicalAttention && !isHigh) ...[
              const SizedBox(height: AppSpacing.stackSm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_hospital, color: scheme.tertiary),
                    const SizedBox(width: AppSpacing.unit),
                    Expanded(
                      child: Text(
                        'Medical evaluation is recommended, especially if symptoms persist, worsen, or new warning signs appear.',
                        style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.stackLg),
            _actions(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              result.disclaimer.isEmpty
                  ? 'This tool provides general health guidance and does not diagnose medical conditions.'
                  : result.disclaimer,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyBanner(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.error.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: scheme.error, size: 28),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: Text(
                  'Seek urgent medical attention',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            'Some of the symptoms you described can be serious. Please seek urgent medical attention or contact your local emergency service, especially if the symptoms are severe, sudden, or getting worse.',
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    ColorScheme scheme,
    String title,
    IconData icon, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.unit),
              Text(
                title,
                style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          ...children,
        ],
      ),
    );
  }

  Widget _bullet(ColorScheme scheme, String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.unit),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.unit),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    final isHigh = result.riskLevel == 'HIGH';
    final isMedium = result.riskLevel == 'MEDIUM';
    if (isHigh) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillButton(
            label: 'Call Emergency Services',
            icon: Icons.call,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling emergency services...')),
              );
            },
          ),
          const SizedBox(height: AppSpacing.unit),
          PillButton(
            label: 'Find Nearest Hospital',
            icon: Icons.directions,
            backgroundColor: scheme.surfaceContainerLowest,
            foregroundColor: scheme.primary,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening maps to nearest hospital...')),
              );
            },
          ),
        ],
      );
    }
    if (isMedium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillButton(
            label: 'Book a Consultation',
            icon: Icons.calendar_month,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          PillButton(
            label: 'Talk to a Doctor',
            icon: Icons.chat_bubble,
            backgroundColor: scheme.surfaceContainerLowest,
            foregroundColor: scheme.primary,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillButton(
          label: 'Continue with Self-Care',
          icon: Icons.self_improvement,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SelfCareAdviceScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        PillButton(
          label: 'Talk to a Doctor',
          icon: Icons.chat_bubble,
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.primary,
          border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
          ),
        ),
      ],
    );
  }
}
