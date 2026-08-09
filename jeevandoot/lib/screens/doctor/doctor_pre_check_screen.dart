import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_ai_suggested_questions_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_video_consult_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorPreCheckScreen extends StatelessWidget {
  const DoctorPreCheckScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Pre-Check',
        hideTrailing: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _card(context, scheme),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            color: scheme.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMd
                            .copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'ID: JD-9942 • Male, ${patient.age} yrs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.unit),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning,
                          size: 14, color: scheme.onErrorContainer),
                      const SizedBox(width: 4),
                      Text(
                        patient.risk.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPORTED SYMPTOMS',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in patient.symptoms)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurface, fontSize: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const Divider(),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'SYSTEM CHECK',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                _checkRow(
                  scheme,
                  icon: Icons.wifi,
                  label: 'Connection',
                  status: 'Good',
                ),
                const SizedBox(height: AppSpacing.unit),
                _checkRow(
                  scheme,
                  icon: Icons.videocam,
                  label: 'Camera',
                  status: 'Ready',
                ),
                const SizedBox(height: AppSpacing.unit),
                _checkRow(
                  scheme,
                  icon: Icons.mic,
                  label: 'Microphone',
                  status: 'Ready',
                ),
                const SizedBox(height: AppSpacing.stackMd),
                PillButton(
                  label: 'AI Suggested Questions',
                  icon: Icons.auto_awesome,
                  backgroundColor: scheme.surfaceContainerLow,
                  foregroundColor: scheme.primary,
                  height: 48,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorAISuggestedQuestionsScreen(
                          patient: patient),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: scheme.inverseSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam,
                            size: 40, color: scheme.onInverseSurface),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.inverseSurface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Video Preview Active',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onInverseSurface, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            color: scheme.surfaceContainer,
            child: Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'Cancel',
                    backgroundColor: scheme.surfaceContainerLowest,
                    foregroundColor: scheme.onSurface,
                    border: Border.all(color: scheme.outline),
                    height: 48,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  flex: 2,
                  child: PillButton(
                    label: 'Start Consultation',
                    icon: Icons.video_call,
                    height: 48,
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorVideoConsultScreen(patient: patient),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 20),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
