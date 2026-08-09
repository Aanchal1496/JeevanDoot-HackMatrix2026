import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

/// What the doctor picked in the override sheet.
typedef TriageOverrideResult = ({TriageBand level, String reason});

/// Opens the shared "Change Triage Level" bottom sheet.
///
/// Returns the chosen level + reason, or null if cancelled.
Future<TriageOverrideResult?> showTriageOverrideSheet(
  BuildContext context, {
  required DoctorPatient patient,
  bool showCurrentFinal = false,
}) {
  return showModalBottomSheet<TriageOverrideResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DoctorTriageOverrideSheet(
      patient: patient,
      showCurrentFinal: showCurrentFinal,
    ),
  );
}

/// 'Change Triage Level' form: current AI assessment, radio-style level
/// selection and a mandatory reason. The original AI assessment is preserved
/// and the change is recorded in the triage history by the backend.
class DoctorTriageOverrideSheet extends StatefulWidget {
  const DoctorTriageOverrideSheet({
    super.key,
    required this.patient,
    this.showCurrentFinal = false,
  });

  final DoctorPatient patient;

  /// Also surface the current *final* level + source inside the AI box.
  final bool showCurrentFinal;

  @override
  State<DoctorTriageOverrideSheet> createState() =>
      _DoctorTriageOverrideSheetState();
}

class _DoctorTriageOverrideSheetState extends State<DoctorTriageOverrideSheet> {
  TriageBand _selected = TriageBand.red;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final patient = widget.patient;
    final reason = _reasonController.text.trim();
    final canConfirm =
        reason.isNotEmpty && _selected != patient.finalTriageLevel;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change Triage Level',
                style: AppTextStyles.headlineLgMobile
                    .copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                '${patient.name} · ${patient.id}',
                style: AppTextStyles.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              _assessmentBox(scheme, patient),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Select new priority',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              for (final band in TriageBand.values) ...[
                _levelOption(scheme, band),
                if (band != TriageBand.values.last)
                  const SizedBox(height: AppSpacing.unit),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Reason for override (required)',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. Patient reports worsening symptoms.',
                  filled: true,
                  fillColor: scheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      backgroundColor: scheme.surfaceContainerLowest,
                      foregroundColor: scheme.onSurface,
                      border: Border.all(color: scheme.outline),
                      height: 50,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    flex: 2,
                    child: PillButton(
                      label: 'Confirm Override',
                      height: 50,
                      onPressed: canConfirm
                          ? () => Navigator.of(context).pop((
                                level: _selected,
                                reason: reason,
                              ))
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'The original AI assessment is preserved and this change is '
                'recorded in the triage history.',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assessmentBox(ColorScheme scheme, DoctorPatient patient) {
    final showFinal = widget.showCurrentFinal ||
        patient.triageSource != TriageSource.ai;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT AI ASSESSMENT',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.outline,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          Row(
            children: [
              Icon(patient.aiTriageLevel.icon,
                  color: patient.aiTriageLevel.color, size: 14),
              const SizedBox(width: 6),
              Text(
                patient.aiTriageLevel.label,
                style: AppTextStyles.labelLg.copyWith(
                  color: patient.aiTriageLevel.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Risk Score: ${patient.aiRiskScore}/100',
                style: AppTextStyles.labelLg.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (showFinal) ...[
            const SizedBox(height: 6),
            Text(
              'Current final level: ${patient.finalTriageLevel.label} '
              '(${patient.triageSource.label})',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _levelOption(ColorScheme scheme, TriageBand band) {
    final selected = _selected == band;
    return Material(
      color: selected
          ? band.color.withValues(alpha: 0.08)
          : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selected = band),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? band.color : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? band.color : scheme.outlineVariant,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.gutter),
              Icon(band.icon, color: band.color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      band.label,
                      style: AppTextStyles.labelLg.copyWith(
                        color: band.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      band.description,
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
