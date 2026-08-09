import 'package:flutter/material.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/book_consultation_screen.dart';
import 'package:jeevandoot/screens/self_care_advice_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key, required this.level});

  final TriageLevel level;

  @override
  Widget build(BuildContext context) {
    switch (level) {
      case TriageLevel.low:
        return _LowRiskScreen();
      case TriageLevel.consult:
        return _ConsultRecommendedScreen();
      case TriageLevel.urgent:
        return _UrgentCareScreen();
    }
  }
}

// ---------------------------------------------------------------------------
// Low Risk
// ---------------------------------------------------------------------------
class _LowRiskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          AppSpacing.stackMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer.withValues(alpha: 0.15),
                      ),
                    ),
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primaryContainer.withValues(alpha: 0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 64,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Triage Complete',
                        style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  'Low Risk',
                  style: AppTextStyles.displayHeroMobile.copyWith(
                    color: scheme.onPrimaryFixedVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  "Your symptoms don't currently show signs of an emergency.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'What you can do',
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _adviceTile(
              scheme,
              icon: Icons.water_drop,
              title: 'Stay hydrated',
              body: 'Drink plenty of water and clear fluids.',
            ),
            const SizedBox(height: AppSpacing.unit),
            _adviceTile(
              scheme,
              icon: Icons.bed,
              title: 'Get adequate rest',
              body: 'Allow your body time to recover and heal.',
            ),
            const SizedBox(height: AppSpacing.unit),
            _adviceTile(
              scheme,
              icon: Icons.thermostat,
              title: 'Monitor your temperature',
              body: 'Check your temperature twice a day and watch for changes in your symptoms.',
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.surfaceContainerHighest),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: scheme.secondary, size: 20),
                  const SizedBox(width: AppSpacing.unit),
                  Expanded(
                    child: Text(
                      'Watch for changes in your symptoms. If they worsen unexpectedly, retake the assessment or seek medical advice.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            PillButton(
              label: 'Continue with Self-Care',
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
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Center(
              child: Text(
                "This assessment is for guidance and does not replace a medical professional's diagnosis or advice.",
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.outline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adviceTile(
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
                Text(
                  body,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Consultation Recommended
// ---------------------------------------------------------------------------
class _ConsultRecommendedScreen extends StatelessWidget {
  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBjEQW8XRhQwFEG-PZEUhfbu0KqQyC23_d0yBxla-jI7jFOsvpSlLxd5Zd91mzHvfC54BNbGEb1F_k9sKUxu5LAHoQa_ocM3yaT9Q-J9ULEcWNwSm6tnBKh6U2V-QjiVqGBqw84uCED9mVj6WKCfGwOUsQUuCY5IgN5mkUwnmkQ7MEH5T9BqZ69AqDJH7CPU3OiIJQu4AzUSOZlnRzR-MzCsdOR-vr7Y4aInGejSpmdd_j9tMljS3ax';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        avatarUrl: _avatarUrl,
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
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.3),
                      width: 4,
                    ),
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.tertiaryContainer.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning,
                    size: 48,
                    color: scheme.tertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              'Medical attention recommended',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Some of your symptoms may need to be checked by a doctor to ensure your well-being.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            PillButton(
              label: 'Book a Consultation',
              icon: Icons.calendar_month,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            PillButton(
              label: 'View Symptoms',
              icon: Icons.list_alt,
              backgroundColor: scheme.surfaceContainerHigh,
              foregroundColor: scheme.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'Why are we recommending a consultation?',
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _factorIcon(scheme, Icons.thermostat, scheme.errorContainer, scheme.error),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Persistent High Fever',
                          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          'Your reported fever has lasted more than 3 days, which requires medical evaluation.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _factorIcon(
                    scheme,
                    Icons.air,
                    scheme.tertiaryContainer.withValues(alpha: 0.2),
                    scheme.tertiaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mild Shortness of Breath',
                          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          'Coupled with fever, respiratory symptoms should be monitored by a healthcare professional.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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

  Widget _factorIcon(ColorScheme scheme, IconData icon, Color bg, Color fg) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg),
    );
  }
}

// ---------------------------------------------------------------------------
// Urgent Care
// ---------------------------------------------------------------------------
class _UrgentCareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'JeevanDoot',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emergency, size: 48, color: scheme.error),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Urgent medical attention needed',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.error),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'Some of your symptoms may require immediate medical care.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.error.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: scheme.onErrorContainer),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Text(
                      'If you feel your condition is getting worse, seek immediate medical help.',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Row(
              children: [
                Icon(Icons.local_hospital, color: scheme.primary),
                const SizedBox(width: AppSpacing.unit),
                Text(
                  'Nearest facility',
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    color: scheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.map,
                        size: 48,
                        color: scheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'District General Hospital',
                                style: AppTextStyles.headlineLgMobile.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '2.5 km',
                                style: AppTextStyles.labelLg
                                    .copyWith(color: scheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.unit),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 20, color: scheme.primary),
                            const SizedBox(width: AppSpacing.unit),
                            Text(
                              'Open 24/7',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.unit,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Emergency Ward Available',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            PillButton(
              label: 'Find Nearest Hospital',
              icon: Icons.directions,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening maps to nearest hospital...')),
                );
              },
            ),
            const SizedBox(height: AppSpacing.stackSm),
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
          ],
        ),
      ),
    );
  }
}
