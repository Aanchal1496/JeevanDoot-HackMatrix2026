import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_prescription_preview_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorConsultationNotesScreen extends StatelessWidget {
  const DoctorConsultationNotesScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: AppStrings.tr('Consultation Notes'),
        trailingIcon: Icons.ios_share,
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.tr('Notes shared to patient.'))),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _aiSummaryCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _notesFieldCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _bottomBar(context, scheme),
          ],
        ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 24),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
              ),
              Text(
                'Male, ${patient.age} yrs • Follow-up',
                style: AppTextStyles.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiSummaryCard(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            color: scheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.tr('AI Summary'),
                    style: AppTextStyles.labelLg
                        .copyWith(color: scheme.onPrimaryContainer),
                  ),
                ),
                Text(
                  AppStrings.tr('Auto-generated'),
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Text(
              AppStrings.tr(
                'Patient presented with fever (101°F) and persistent cough for 3 days. '
                'Oxygen saturation normal at 98%. Based on symptoms and vitals, patient '
                'shows moderate risk of respiratory tract infection. Continue current '
                'medication and monitor temperature every 6 hours.',
              ),
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesFieldCard(ColorScheme scheme) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr('DOCTOR NOTES'),
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppStrings.tr('Draft'),
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: AppStrings.tr('Type your consultation notes here...'),
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(AppSpacing.gutter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            AppStrings.tr('DOCTOR VITALS'),
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          Row(
            children: [
              Expanded(
                child: _vitalChip(scheme, AppStrings.tr('Temp'), '101.2°F'),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: _vitalChip(scheme, AppStrings.tr('Pulse'), '88 bpm'),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: _vitalChip(scheme, AppStrings.tr('BP'), '122/81'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalChip(ColorScheme scheme, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelLg.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: PillButton(
              label: AppStrings.tr('Preview'),
              icon: Icons.description_outlined,
              backgroundColor: scheme.surfaceContainerLow,
              foregroundColor: scheme.primary,
              height: 48,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DoctorPrescriptionPreviewScreen(patient: patient),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            flex: 2,
            child: PillButton(
              label: AppStrings.tr('Send to Patient'),
              icon: Icons.send,
              height: 48,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.tr('Notes saved.'))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
