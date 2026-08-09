import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';

class DoctorConsultationInfoPanelScreen extends StatelessWidget {
  const DoctorConsultationInfoPanelScreen({
    super.key,
    required this.patient,
    this.fromVideo = false,
  });

  final DoctorPatient patient;
  final bool fromVideo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Patient Information',
        hideTrailing: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        children: [
          _headerCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _vitalsRow(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _infoSection(
            scheme,
            icon: Icons.medical_information,
            color: scheme.primary,
            title: 'Previous Conditions',
            items: const ['Hypertension (2018)', 'Type 2 Diabetes (2020)'],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _infoSection(
            scheme,
            icon: Icons.healing,
            color: scheme.tertiary,
            title: 'Allergies',
            items: const ['Penicillin (Mild rash)', 'Dust mites'],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _infoSection(
            scheme,
            icon: Icons.medication,
            color: scheme.primary,
            title: 'Current Medications',
            items: const ['Metformin 500mg (Daily)', 'Lisinopril 10mg (Daily)'],
          ),
        ],
      ),
    );
  }

  Widget _headerCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 28),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient.age} yrs · ${patient.gender} · ${patient.id}',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: patient.risk.level == DoctorRiskLevel.low
                        ? scheme.primaryContainer
                        : scheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    patient.risk.label.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: patient.risk.level == DoctorRiskLevel.low
                          ? scheme.onPrimaryContainer
                          : scheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
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

  Widget _vitalsRow(ColorScheme scheme) {
    final vitals = [
      (label: 'Temp', value: '101.2°F'),
      (label: 'Pulse', value: '88 bpm'),
      (label: 'BP', value: '122/81'),
    ];
    return Row(
      children: [
        for (var i = 0; i < vitals.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.stackSm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    vitals[i].label,
                    style: AppTextStyles.labelSm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vitals[i].value,
                    style: AppTextStyles.labelLg.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < vitals.length - 1) const SizedBox(width: AppSpacing.unit),
        ],
      ],
    );
  }

  Widget _infoSection(
    ColorScheme scheme, {
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.unit),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $item',
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
