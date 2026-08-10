import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/book_consultation_screen.dart';
import 'package:jeevandoot/screens/offline_screen.dart';
import 'package:jeevandoot/screens/symptom_checker_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Results of a symptom check. Driven by the backend's analysis payload so the
/// symptoms, score, explanation, red flags and self-care are always in sync.
class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key, required this.result});

  final SymptomCheckResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultView(result: result);
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final SymptomCheckResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (result.queued) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          leading: BackButton(color: scheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 64, color: scheme.primary),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  AppStrings.tr('Symptom check saved'),
                  style: AppTextStyles.displayHeroMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  AppStrings.tr('You appear to be offline. Your check was saved on this device and will be sent to a doctor when you reconnect.'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                PillButton(
                  label: AppStrings.tr('View Sync Status'),
                  icon: Icons.sync,
                  height: 48,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OfflineScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isHigh = result.isHigh;
    final isMedium = result.isMedium;

    final (Color bg, Color dot, IconData icon, String label) = isHigh
        ? (scheme.errorContainer, scheme.error, Icons.emergency, AppStrings.tr('High Risk'))
        : isMedium
            ? (scheme.tertiaryContainer.withValues(alpha: 0.25), scheme.tertiaryContainer, Icons.warning, AppStrings.tr('Medium Risk'))
            : (scheme.primaryContainer.withValues(alpha: 0.25), scheme.primary, Icons.check_circle, AppStrings.tr('Low Risk'));

    final headline = isHigh
        ? AppStrings.tr('Urgent medical attention needed')
        : isMedium
            ? AppStrings.tr('Medical attention recommended')
            : AppStrings.tr('Your symptoms look low risk');

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.stackMd,
              AppSpacing.containerMargin,
              AppSpacing.stackLg,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(scheme, dot, icon, label, headline),
                  const SizedBox(height: AppSpacing.stackLg),
                  if (result.redFlags.isNotEmpty) ...[
                    _redFlagsSection(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],
                  _raisedCard(scheme, _symptomsSection(scheme)),
                  const SizedBox(height: AppSpacing.stackMd),
                  _raisedCard(scheme, _explanationSection(scheme)),
                  const SizedBox(height: AppSpacing.stackMd),
                  _raisedCard(scheme, _selfCareSection(scheme)),
                  const SizedBox(height: AppSpacing.stackLg),
                  _actions(context, scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  Center(
                    child: Text(
                      AppStrings.tr("This assessment is for guidance only and does not replace a "
                      "medical professional's diagnosis or advice."),
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
          ),
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme, Color dot, IconData icon, String label, String headline) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot.withValues(alpha: 0.12),
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
                    color: dot.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 64, color: dot),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Risk Level: $label',
            style: AppTextStyles.labelLg.copyWith(color: dot, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Risk score ${result.riskScore} out of 100',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          result.explanation,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _redFlagsSection(ColorScheme scheme) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
              const SizedBox(width: AppSpacing.unit),
              Text(
                AppStrings.tr('Important'),
                style: AppTextStyles.headlineMd.copyWith(color: scheme.onErrorContainer),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          for (final flag in result.redFlags)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      flag,
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            AppStrings.tr('Seek urgent medical attention now. Do not rely on home self-care.'),
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onErrorContainer),
          ),
        ],
      ),
    );
  }

  Widget _raisedCard(ColorScheme scheme, Widget child) {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _symptomsSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr('Symptoms detected'),
          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        if (result.symptoms.isEmpty)
          Text(
            AppStrings.tr('No specific symptoms could be identified.'),
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in result.symptoms)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: s.redFlag ? scheme.errorContainer : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: s.redFlag ? scheme.error : scheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_information, size: 16, color: s.redFlag ? scheme.error : scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        s.name,
                        style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                      ),
                      if (s.severity != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${s.severity})',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _explanationSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: scheme.secondary),
            const SizedBox(width: AppSpacing.unit),
            Text(
              AppStrings.tr('Why this result'),
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          result.explanation,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _selfCareSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(result.isHigh ? Icons.local_hospital : Icons.self_improvement,
                size: 20, color: scheme.primary),
            const SizedBox(width: AppSpacing.unit),
            Text(
              result.isHigh ? AppStrings.tr('Recommended next step') : AppStrings.tr('Next steps'),
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        for (final step in result.selfCare)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.unit),
                Expanded(
                  child: Text(
                    step,
                    style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _actions(BuildContext context, ColorScheme scheme) {
    if (result.isHigh) {
      return Column(
        children: [
          PillButton(
            label: AppStrings.tr('Find Hospital'),
            icon: Icons.local_hospital,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            onPressed: () => _toast(context, AppStrings.tr('Opening map to nearest hospital...')),
          ),
          const SizedBox(height: AppSpacing.unit),
          _secondaryButton(scheme, Icons.restart_alt, AppStrings.tr('Check Again'),
              () => _restart(context)),
        ],
      );
    }
    if (result.isMedium) {
      return Column(
        children: [
          PillButton(
            label: AppStrings.tr('Book a Consultation'),
            icon: Icons.calendar_month,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          _secondaryButton(scheme, Icons.restart_alt, AppStrings.tr('Check Again'),
              () => _restart(context)),
        ],
      );
    }
    return Column(
      children: [
        PillButton(
          label: AppStrings.tr('Get Self-Care Tips'),
          icon: Icons.self_improvement,
          onPressed: () =>
              _toast(context, AppStrings.tr('Self-care guidance can be found above.')),
        ),
        const SizedBox(height: AppSpacing.unit),
        _secondaryButton(
            scheme, Icons.restart_alt, AppStrings.tr('Check Again'), () => _restart(context)),
      ],
    );
  }

  Widget _secondaryButton(
      ColorScheme scheme, IconData icon, String label, VoidCallback onTap) {
    return PillButton(
      label: label,
      icon: icon,
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.primary,
      border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      onPressed: onTap,
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _restart(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
      (route) => false,
    );
  }
}