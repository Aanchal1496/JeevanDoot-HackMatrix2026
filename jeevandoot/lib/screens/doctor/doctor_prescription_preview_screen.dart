import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_new_prescription_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorPrescriptionPreviewScreen extends StatelessWidget {
  const DoctorPrescriptionPreviewScreen({
    super.key,
    required this.patient,
    this.prescription,
  });

  final DoctorPatient patient;

  /// The prescription just saved by the doctor. When null the screen shows
  /// demo content (e.g. opened straight from the consultation notes flow).
  final Prescription? prescription;

  String get _date => prescription?.date.isNotEmpty == true
      ? prescription!.date
      : '08 Aug 2026';

  List<PrescriptionItem> get _medicines =>
      prescription?.medicines ?? const [];

  String get _notes => prescription?.notes ?? '';

  String _dose(PrescriptionItem m) => '${m.dosage}${m.unit}';

  String _times(PrescriptionItem m) {
    final parts = <String>[
      if (m.morning > 0) 'M',
      if (m.afternoon > 0) 'A',
      if (m.night > 0) 'N',
    ];
    return parts.isEmpty ? '—' : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Prescription Preview',
        trailingIcon: Icons.ios_share,
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescription shared.')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _previewCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _bottomBar(context, scheme),
          ],
        ),
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
                        value: patient.name,
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
                  value: '${patient.age} yrs · ${patient.gender}',
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
                      name: 'Paracetamol', dose: '650mg', times: 'M / N'),
                  _medicineRow(scheme,
                      name: 'Azithromycin', dose: '500mg', times: 'A'),
                  _medicineRow(scheme,
                      name: 'Cough Syrup', dose: '10ml', times: 'M / A / N'),
                ] else
                  for (final m in _medicines)
                    _medicineRow(scheme,
                        name: m.name, dose: _dose(m), times: _times(m)),
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
    required String times,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.unit),
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.medication, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
            ),
          ),
          Text(
            dose,
            style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              times,
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: PillButton(
            label: 'Edit',
            backgroundColor: scheme.surfaceContainerLowest,
            foregroundColor: scheme.onSurface,
            border: Border.all(color: scheme.outline),
            height: 48,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DoctorNewPrescriptionScreen(patient: patient),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          flex: 2,
          child: PillButton(
            label: 'Send Prescription',
            icon: Icons.send,
            height: 48,
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescription sent to patient.')),
              );
            },
          ),
        ),
      ],
    );
  }
}
