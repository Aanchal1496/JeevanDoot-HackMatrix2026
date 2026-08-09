import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_prescription_preview_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Read-only review of a prescription draft. The doctor must explicitly
/// confirm; the backend revalidates before issuing.
class DoctorPrescriptionReviewScreen extends StatefulWidget {
  const DoctorPrescriptionReviewScreen({
    super.key,
    required this.patient,
    required this.prescription,
    required this.allergies,
  });

  final DoctorPatient patient;
  final Prescription prescription;
  final List<String> allergies;

  @override
  State<DoctorPrescriptionReviewScreen> createState() =>
      _DoctorPrescriptionReviewScreenState();
}

class _DoctorPrescriptionReviewScreenState
    extends State<DoctorPrescriptionReviewScreen> {
  bool _issuing = false;

  Prescription get _rx => widget.prescription;

  Future<void> _confirm() async {
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Prescription?'),
        content: const Text(
          'Please verify:\n\n'
          '✓ Patient\n'
          '✓ Medicines\n'
          '✓ Dosages\n'
          '✓ Frequency\n'
          '✓ Duration\n'
          '✓ Instructions\n'
          '✓ Allergy warnings\n\n'
          'Once confirmed, this prescription will be added to the '
          "patient's medical record.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Confirm & Issue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _issuing = true);
    try {
      final issued = await issuePrescription(_rx.id);
      await clearLocalDraft(widget.patient.patientId.isNotEmpty
          ? widget.patient.patientId
          : widget.patient.id);
      if (!mounted) return;
      setState(() => _issuing = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Prescription issued (${issued.id}).')),
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DoctorPrescriptionPreviewScreen(
            patient: widget.patient,
            prescription: issued,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _issuing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Review Prescription',
        hideTrailing: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        children: [
          _reviewCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _verifyBanner(scheme),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          AppSpacing.containerMargin,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Back to Edit',
                height: 48,
                backgroundColor: scheme.surfaceContainerLow,
                foregroundColor: scheme.onSurface,
                border: Border.all(color: scheme.outlineVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              flex: 2,
              child: PillButton(
                label: 'Confirm Prescription',
                icon: Icons.verified_outlined,
                height: 48,
                loading: _issuing,
                onPressed: _issuing ? null : _confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(ColorScheme scheme) {
    final patient = widget.patient;
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
              Expanded(
                child: _infoBlock(scheme,
                    label: 'PATIENT', value: patient.name),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _infoBlock(scheme,
                    label: 'PATIENT ID',
                    value: patient.patientId.isNotEmpty
                        ? patient.patientId
                        : patient.id),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _infoBlock(scheme,
              label: 'AGE / GENDER',
              value: '${patient.age} yrs • ${patient.gender}'),
          if (widget.allergies.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allergies',
                          style: AppTextStyles.labelSm.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.allergies.join(', '),
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurface, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          const Divider(),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'MEDICINES',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          for (var i = 0; i < _rx.medicines.length; i++)
            _medicineReviewRow(scheme, _rx.medicines[i], i + 1),
          if (_rx.additionalInstructions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'ADDITIONAL INSTRUCTIONS',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _rx.additionalInstructions,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoBlock(ColorScheme scheme,
      {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            color: scheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _medicineReviewRow(
      ColorScheme scheme, PrescriptionItem item, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.unit),
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.unit),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.strength.isNotEmpty
                      ? '${item.name} ${item.strength}'
                      : item.name,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.doseLine,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                if (item.instructions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.instructions,
                    style: AppTextStyles.labelSm
                        .copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifyBanner(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Please verify all medicines, doses, and instructions. '
              'This prescription documentation tool assists the doctor and '
              'does not replace professional clinical judgment.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
