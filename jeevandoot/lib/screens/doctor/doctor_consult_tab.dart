import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_pre_check_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorConsultTab extends StatelessWidget {
  const DoctorConsultTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Consult',
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'CONSULTATION',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Active Consultations',
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Start or resume a consultation for a waiting patient.',
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _consultCard(
              context,
              scheme,
              patient: kDoctorPatients.first,
              isActive: true,
            ),
            const SizedBox(height: AppSpacing.gutter),
            _consultCard(
              context,
              scheme,
              patient: kDoctorPatients[1],
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _consultCard(
    BuildContext context,
    ColorScheme scheme, {
    required DoctorPatient patient,
    required bool isActive,
  }) {
    return SoftCard(
      border: Border(
        left: BorderSide(color: patient.risk.color, width: 4),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DoctorPatientCaseScreen(patient: patient),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.videocam : Icons.schedule,
                  color: isActive
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age} · ${patient.gender}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: patient.risk.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  patient.risk.label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: patient.risk.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          PillButton(
            label: isActive ? 'Resume Consultation' : 'Start Consultation',
            backgroundColor: isActive ? scheme.primary : scheme.surfaceContainer,
            foregroundColor: isActive ? scheme.onPrimary : scheme.onSurface,
            height: 48,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DoctorPreCheckScreen(patient: patient),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
