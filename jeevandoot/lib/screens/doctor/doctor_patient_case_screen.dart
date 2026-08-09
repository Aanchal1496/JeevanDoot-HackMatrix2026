import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_consultation_notes_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_pre_check_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_referral_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorPatientCaseScreen extends StatefulWidget {
  const DoctorPatientCaseScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorPatientCaseScreen> createState() => _DoctorPatientCaseScreenState();
}

class _DoctorPatientCaseScreenState extends State<DoctorPatientCaseScreen> {
  final Set<int> _expanded = {};
  PatientCase? _case;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final caseData = await fetchPatientCase(widget.patient.id);
      if (!mounted) return;
      setState(() => _case = caseData);
    } catch (_) {
      // Fall back to the header-only patient data when offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final patient = widget.patient;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Patient Case',
        trailingIcon: Icons.more_vert,
        onTrailing: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        children: [
          _headerCard(context, scheme, patient),
          const SizedBox(height: AppSpacing.stackMd),
          _triageCard(scheme, patient),
          const SizedBox(height: AppSpacing.stackMd),
          _vitalsCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _historyCard(scheme),
        ],
      ),
    );
  }

  Widget _headerCard(
      BuildContext context, ColorScheme scheme, DoctorPatient patient) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: patient.risk.color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      style: AppTextStyles.headlineLgMobile
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.age} years · ${patient.gender}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
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
                  borderRadius: BorderRadius.circular(8),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: _filledAction(
                  scheme,
                  label: 'Start Consultation',
                  icon: Icons.medical_services,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorPreCheckScreen(patient: patient),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _outlineAction(
                  scheme,
                  label: 'Refer Patient',
                  icon: Icons.share,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorReferralScreen(patient: patient),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.unit),
          _outlineAction(
            scheme,
            label: 'Write Consultation Notes',
            icon: Icons.edit_note,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DoctorConsultationNotesScreen(patient: patient),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filledAction(
    ColorScheme scheme, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return PillButton(
      label: label,
      icon: icon,
      height: 48,
      onPressed: onTap,
    );
  }

  Widget _outlineAction(
    ColorScheme scheme, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return PillButton(
      label: label,
      icon: icon,
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.secondary,
      border: Border.all(color: scheme.secondary),
      height: 48,
      onPressed: onTap,
    );
  }

  Widget _triageCard(ColorScheme scheme, DoctorPatient patient) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy,
                    size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 8),
              Text(
                'AI-Assisted Triage',
                style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
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
                    color: scheme.surfaceContainerLowest,
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackSm),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: scheme.error, width: 4)),
            ),
            child: Text(
              _case?.aiSummary.isNotEmpty ?? false
                  ? _case!.aiSummary
                  : 'Summary: Patient-reported symptoms indicate that urgent clinical evaluation may be appropriate.',
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface, fontSize: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(Icons.info, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'AI suggestions do not replace professional medical judgment.',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalsCard(ColorScheme scheme) {
    final v = _case?.vitals ?? const {};
    final vitals = [
      (icon: Icons.device_thermostat, label: 'Temp', value: v['temp'] ?? '38.7', unit: '°C', color: scheme.tertiary, alert: false),
      (icon: Icons.favorite, label: 'HR', value: v['hr'] ?? '102', unit: 'bpm', color: scheme.tertiary, alert: false),
      (icon: Icons.air, label: 'SpO2', value: v['spo2'] ?? '94', unit: '%', color: scheme.onErrorContainer, alert: true),
      (icon: Icons.bloodtype, label: 'BP', value: v['bp'] ?? '138/90', unit: 'mmHg', color: scheme.primary, alert: false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT VITALS',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Row(
          children: [
            for (var i = 0; i < vitals.length; i++) ...[
              Expanded(child: _vitalCard(scheme, vitals[i])),
              if (i < vitals.length - 1) const SizedBox(width: AppSpacing.unit),
            ],
          ],
        ),
      ],
    );
  }

  Widget _vitalCard(
    ColorScheme scheme,
    ({
      IconData icon,
      String label,
      String value,
      String unit,
      Color color,
      bool alert,
    }) vital,
  ) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: vital.alert ? scheme.errorContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vital.alert
              ? scheme.error.withValues(alpha: 0.2)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(vital.icon, size: 16, color: vital.color),
              Text(
                vital.label,
                style: AppTextStyles.labelSm.copyWith(
                  color: vital.color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  vital.value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: vital.color,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                vital.unit,
                style: AppTextStyles.labelSm.copyWith(
                  color: vital.color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyCard(ColorScheme scheme) {
    final h = _case?.history ?? const {};
    final sections = [
      (
        icon: Icons.medical_information,
        color: scheme.primary,
        title: 'Previous Conditions',
        items: h['conditions']?.isNotEmpty == true
            ? h['conditions']!
            : ['Hypertension (Diagnosed 2018)', 'Type 2 Diabetes (Diagnosed 2020)'],
      ),
      (
        icon: Icons.healing,
        color: scheme.tertiary,
        title: 'Allergies',
        items: h['allergies']?.isNotEmpty == true
            ? h['allergies']!
            : ['Penicillin (Mild rash)', 'Dust mites'],
      ),
      (
        icon: Icons.medication,
        color: scheme.primary,
        title: 'Current Medications',
        items: h['medications']?.isNotEmpty == true
            ? h['medications']!
            : ['Metformin 500mg (Daily)', 'Lisinopril 10mg (Daily)'],
      ),
      (
        icon: Icons.history,
        color: scheme.primary,
        title: 'Previous Consultations',
        items: h['consultations']?.isNotEmpty == true
            ? h['consultations']!
            : ['Routine Checkup — Dr. Sharma · 12 Oct 2023'],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEDICAL HISTORY',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        for (var i = 0; i < sections.length; i++) ...[
          _accordion(scheme, index: i, section: sections[i]),
          if (i < sections.length - 1) const SizedBox(height: AppSpacing.unit),
        ],
      ],
    );
  }

  Widget _accordion(
    ColorScheme scheme, {
    required int index,
    required ({
      IconData icon,
      Color color,
      String title,
      List<String> items,
    }) section,
  }) {
    final open = _expanded.contains(index);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              open ? _expanded.remove(index) : _expanded.add(index);
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.stackSm,
              ),
              child: Row(
                children: [
                  Icon(section.icon, color: section.color, size: 20),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Text(
                      section.title,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurface, fontSize: 15),
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.gutter,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.unit),
                  for (final item in section.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $item',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
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
