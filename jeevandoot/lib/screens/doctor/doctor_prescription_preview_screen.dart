import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

/// The issued prescription view. Once issued the prescription is immutable;
/// the doctor can download the PDF but cannot silently edit it.
class DoctorPrescriptionPreviewScreen extends StatefulWidget {
  const DoctorPrescriptionPreviewScreen({
    super.key,
    required this.patient,
    this.prescription,
    this.onCancelled,
  });

  final DoctorPatient patient;

  /// The issued prescription. When null the screen shows demo content
  /// (e.g. opened straight from the consultation notes flow).
  final Prescription? prescription;

  /// Called when the doctor cancels the prescription so the caller can
  /// refresh its list (e.g. prescription history).
  final ValueChanged<Prescription>? onCancelled;

  @override
  State<DoctorPrescriptionPreviewScreen> createState() =>
      _DoctorPrescriptionPreviewScreenState();
}

class _DoctorPrescriptionPreviewScreenState
    extends State<DoctorPrescriptionPreviewScreen> {
  bool _downloading = false;
  bool _cancelling = false;

  /// Mutable copy of the prescription so a cancel can re-render the banner.
  late Prescription? _prescription;

  @override
  void initState() {
    super.initState();
    _prescription = widget.prescription;
  }

  Prescription? get _rx => _prescription;

  String get _date => _rx?.date.isNotEmpty == true
      ? _rx!.date
      : '08 Aug 2026';

  List<PrescriptionItem> get _medicines => _rx?.medicines ?? const [];

  String get _notes =>
      _rx?.additionalInstructions.isNotEmpty == true
          ? _rx!.additionalInstructions
          : (_rx?.notes ?? '');

  Future<void> _downloadPdf() async {
    final rx = _rx;
    if (rx == null || !rx.isIssued) return;
    setState(() => _downloading = true);
    try {
      final bytes = await downloadPrescriptionPdf(rx.id);
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF downloaded (${rx.id}) — ${bytes.length ~/ 1024} KB.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download the PDF: $e')),
      );
    }
  }

  Future<void> _cancelPrescription() async {
    final rx = _rx;
    if (rx == null) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _CancelPrescriptionDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _cancelling = true);
    try {
      final cancelled = await cancelPrescription(rx.id, reason: reason.trim());
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _prescription = cancelled;
      });
      widget.onCancelled?.call(cancelled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Prescription ${rx.id} cancelled. The original record is preserved.'
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel the prescription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rx = _rx;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Prescription',
        trailingIcon: Icons.ios_share,
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription shared to patient.')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rx != null) ...[
              if (rx.isIssued)
                _statusBanner(scheme, 'ISSUED', rx.id, issued: true)
              else if (rx.status == PrescriptionStatus.cancelled)
                _statusBanner(scheme, 'CANCELLED', rx.id, issued: false),
              const SizedBox(height: AppSpacing.stackMd),
            ],
            _previewCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _bottomBar(context, scheme),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(
      ColorScheme scheme, String label, String rxId,
      {required bool issued}) {
    final color = issued ? const Color(0xFF15803D) : scheme.onSurfaceVariant;
    final bg = issued ? const Color(0xFFDCFCE7) : scheme.surfaceContainerLow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(issued ? Icons.check_circle : Icons.cancel,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label • $rxId',
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (issued)
            Text(
              issued ? 'Immutable record' : '',
              style: AppTextStyles.labelSm
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _previewCard(ColorScheme scheme) {
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DoctorState.clinic,
                        style: AppTextStyles.headlineMd
                            .copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DoctorState.doctorName,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${DoctorState.specialization} · Reg: ${DoctorState.registrationId}',
                        style: AppTextStyles.labelSm
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_hospital,
                      size: 20, color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoBlock(
                        scheme,
                        label: 'PATIENT',
                        value: widget.patient.name,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: _infoBlock(
                        scheme,
                        label: 'DATE',
                        value: _date,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                _infoBlock(
                  scheme,
                  label: 'AGE / GENDER',
                  value: '${widget.patient.age} yrs · ${widget.patient.gender}',
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const Divider(),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'PRESCRIBED MEDICINES',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                if (_medicines.isEmpty) ...[
                  _medicineRow(scheme,
                      name: 'Paracetamol', dose: '1 tablet twice daily after food for 3 days'),
                  _medicineRow(scheme,
                      name: 'Azithromycin', dose: '1 tablet once daily after food for 3 days'),
                  _medicineRow(scheme,
                      name: 'Cough Syrup', dose: '10 ml three times daily after food for 5 days'),
                ] else
                  for (final m in _medicines)
                    _medicineRow(
                      scheme,
                      name: m.strength.isNotEmpty
                          ? '${m.name} ${m.strength}'
                          : m.name,
                      dose: m.doseLine.isEmpty ? '—' : m.doseLine,
                    ),
                const SizedBox(height: AppSpacing.stackMd),
                const Divider(),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  'INSTRUCTIONS',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  _notes.isNotEmpty
                      ? _notes
                      : '1. Take medicines with food. 2. Drink plenty of fluids. '
                          '3. Follow up in 5 days if symptoms persist.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          padding: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: scheme.onSurface,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Text(
                            DoctorState.doctorName,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelLg
                                .copyWith(color: scheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Digitally Signed',
                          style: AppTextStyles.labelSm.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _medicineRow(
    ColorScheme scheme, {
    required String name,
    required String dose,
  }) {
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
          Icon(Icons.medication, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dose,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, ColorScheme scheme) {
    final rx = _rx;
    final isIssued = rx != null && rx.isIssued;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isIssued) ...[
          OutlinedButton.icon(
            onPressed: _cancelling ? null : _cancelPrescription,
            icon: _cancelling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.block, size: 18),
            label: const Text('Cancel Prescription'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
        ],
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: isIssued ? 'Back' : 'Edit',
                icon: isIssued ? Icons.arrow_back : Icons.edit,
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
                label: 'Download PDF',
                icon: Icons.download,
                height: 48,
                loading: _downloading,
                onPressed: _downloading ? null : _downloadPdf,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Asks the doctor for a mandatory reason before cancelling a prescription.
class _CancelPrescriptionDialog extends StatefulWidget {
  const _CancelPrescriptionDialog();

  @override
  State<_CancelPrescriptionDialog> createState() =>
      _CancelPrescriptionDialogState();
}

class _CancelPrescriptionDialogState extends State<_CancelPrescriptionDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Cancel Prescription?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The prescription will be marked CANCELLED. The original record '
            'and its audit trail are preserved - a correction should be '
            'issued as a new prescription.',
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          TextField(
            controller: _reason,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Reason for cancellation (required)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Prescription'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () {
            if (_reason.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a reason for cancellation.'),
                ),
              );
              return;
            }
            Navigator.of(context).pop(_reason.text);
          },
          child: const Text('Cancel Prescription'),
        ),
      ],
    );
  }
}
