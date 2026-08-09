import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeevandoot/models/case_file_models.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_pre_check_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_referral_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/doctor_triage_override_sheet.dart';

/// Pre-consultation case file: a concise, structured clinical overview the
/// doctor reviews before the consultation begins. All sections are assembled
/// by the backend in one request (no N+1 page loads).
class DoctorPatientCaseScreen extends StatefulWidget {
  const DoctorPatientCaseScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorPatientCaseScreen> createState() => _DoctorPatientCaseScreenState();
}

class _DoctorPatientCaseScreenState extends State<DoctorPatientCaseScreen> {
  CaseFile? _file;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  bool _overriding = false;
  bool _savingSummary = false;
  Timer? _pollTimer;
  final Set<String> _expanded = {};

  String get _patientId =>
      widget.patient.patientId.isNotEmpty ? widget.patient.patientId : widget.patient.id;

  @override
  void initState() {
    super.initState();
    _load();
    // Lightweight polling (no WebSocket infra in this project): the case file
    // refreshes when vitals, symptoms, risk or triage change.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final file = await fetchCaseFile(_patientId);
      if (!mounted) return;
      setState(() {
        _file = file;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final file = await fetchCaseFile(_patientId);
      if (!mounted) return;
      setState(() {
        _file = file;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  DoctorPatient get _patient => widget.patient;

  CaseFilePatient? get _p => _file?.patient;

  // -------------------------------------------------------------------------
  // Layout: two-column clinical dashboard on wide screens, stacked on mobile
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Case File',
        trailingIcon: Icons.refresh,
        onTrailing: _refreshing ? null : () => _refresh(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _body(scheme),
      ),
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_loading && _file == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (_error != null && _file == null) {
      return _errorState(scheme);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final left = <Widget>[
          _headerCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _aiSummaryCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _historyCard(scheme),
        ];
        final right = <Widget>[
          _riskCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _vitalsCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _flagsCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _insightsCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          _timestampsCard(scheme),
        ];

        if (wide) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.unit,
              AppSpacing.containerMargin,
              AppSpacing.stackLg,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: left)),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(child: Column(children: right)),
                ],
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.unit,
            AppSpacing.containerMargin,
            AppSpacing.stackLg,
          ),
          children: [
            ...left,
            const SizedBox(height: AppSpacing.stackMd),
            ...right,
          ],
        );
      },
    );
  }

  Widget _errorState(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Case file unavailable',
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Showing the triage summary available on this device. '
              'Start the backend and pull to refresh.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            SizedBox(
              width: 220,
              child: PillButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: _load,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section shell
  // -------------------------------------------------------------------------

  Widget _sectionCard(
    ColorScheme scheme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          child,
        ],
      ),
    );
  }

  Widget _notAvailable(ColorScheme scheme, String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMd.copyWith(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Patient header
  // -------------------------------------------------------------------------

  Widget _headerCard(ColorScheme scheme) {
    final p = _p;
    final name = p?.name ?? _patient.name;
    final age = p?.age.isNotEmpty == true ? p!.age : _patient.age;
    final gender = p?.gender.isNotEmpty == true ? p!.gender : _patient.gender;
    final blood = (p?.bloodGroup.isNotEmpty == true)
        ? p!.bloodGroup
        : _patient.bloodGroup;
    final band = _file?.riskAssessment.finalTriageLevel ?? _patient.finalTriageLevel;
    final score = _file?.riskAssessment.aiRiskScore ?? _patient.aiRiskScore;
    final wait = p?.waitTime ?? _patient.waitTime;
    final status = p?.queueStatus ?? _patient.status;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: band.color, width: 4)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: band.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, size: 28, color: band.color),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineLgMobile
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$age years • $gender',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient ID: ${p?.patientId ?? _patient.patientId}'
                      '${blood.isNotEmpty ? ' • Blood Group: $blood' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Wrap(
            spacing: AppSpacing.unit,
            runSpacing: AppSpacing.unit,
            children: [
              _chip(scheme,
                  color: band.color, icon: band.icon, text: band.label),
              _chip(
                scheme,
                color: scheme.onSurface,
                icon: Icons.speed,
                text: 'Risk Score: $score/100',
              ),
              _chip(
                scheme,
                color: scheme.onSurfaceVariant,
                icon: Icons.schedule,
                text: 'Waiting: $wait',
              ),
              _chip(
                scheme,
                color: scheme.onSurfaceVariant,
                icon: Icons.access_time_filled,
                text: status.label,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Start Consultation',
                  icon: Icons.medical_services,
                  height: 48,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorPreCheckScreen(patient: _patient),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: PillButton(
                  label: 'Refer Patient',
                  icon: Icons.share,
                  backgroundColor: scheme.surfaceContainerLowest,
                  foregroundColor: scheme.secondary,
                  border: Border.all(color: scheme.secondary),
                  height: 48,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DoctorReferralScreen(patient: _patient),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme scheme,
      {required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AI symptom summary (with doctor edit, original preserved)
  // -------------------------------------------------------------------------

  Widget _aiSummaryCard(ColorScheme scheme) {
    final s = _file?.symptomSummary;
    final summary = s?.aiSummary ?? _patient.aiTriageReason ?? '';
    final hasSummary = summary.trim().isNotEmpty;
    final isEdited = s?.isDoctorEdited == true;

    return _sectionCard(
      scheme,
      icon: Icons.auto_awesome,
      iconColor: scheme.secondary,
      title: 'AI SYMPTOM SUMMARY',
      trailing: _aiBadge(scheme, label: 'AI Generated'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEdited && s != null) ..._doctorEditedBlock(scheme, s),
          if (!hasSummary)
            _notAvailable(scheme, 'Insufficient symptom information available.')
          else ...[
            Text(
              summary,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              'KEY SYMPTOMS',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final symptom in _keySymptomNames())
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      symptom,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurface, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Wrap(
              spacing: AppSpacing.gutter,
              runSpacing: AppSpacing.unit,
              children: [
                _meta(scheme, 'Duration', s?.duration ?? 'Not reported'),
                _meta(scheme, 'Severity', s?.severity ?? 'Not reported'),
                _meta(scheme, 'Onset', s?.onset ?? 'Not reported'),
                _meta(scheme, 'Progression', s?.progression ?? 'Not reported'),
              ],
            ),
            if (s != null && (s.triggers.isNotEmpty || s.aggravatingFactors.isNotEmpty)) ...[
              const SizedBox(height: AppSpacing.stackMd),
              _notReportedRow(scheme, 'Triggers', s.triggers),
              _notReportedRow(scheme, 'Aggravating', s.aggravatingFactors),
              _notReportedRow(scheme, 'Relieving', s.relievingFactors),
            ],
          ],
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: isEdited ? 'Edit Doctor Summary' : 'Edit Summary',
                  icon: Icons.edit_note,
                  height: 44,
                  backgroundColor: scheme.surfaceContainerLow,
                  foregroundColor: scheme.primary,
                  border: Border.all(color: scheme.outlineVariant),
                  loading: _savingSummary,
                  onPressed: _savingSummary ? null : () => _editSummary(scheme),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'AI-generated information should be verified by the '
                  'healthcare professional before clinical decisions.',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
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

  Widget _aiBadge(ColorScheme scheme, {required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 11, color: scheme.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the doctor's edited version with a collapsible original.
  List<Widget> _doctorEditedBlock(
      ColorScheme scheme, CaseFileSymptomSummary s) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: scheme.primary, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, size: 13, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  'DOCTOR SUMMARY',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.primary,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              s.aiSummary,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Edited by: ${s.editedBy ?? 'Doctor'}'
              '${s.editedAt != null && s.editedAt!.isNotEmpty ? ' • ${_shortWhen(s.editedAt!)}' : ''}',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      if (s.originalAiSummary.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.stackSm),
        _originalAiToggle(scheme, s.originalAiSummary),
      ],
    ];
  }

  Widget _originalAiToggle(ColorScheme scheme, String original) {
    final open = _expanded.contains('original_ai');
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              open
                  ? _expanded.remove('original_ai')
                  : _expanded.add('original_ai');
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackSm,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy, size: 16, color: scheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View Original AI Summary',
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
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
                AppSpacing.stackSm,
                0,
                AppSpacing.stackSm,
                AppSpacing.stackSm,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Text(
                original,
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _keySymptomNames() {
    final s = _file?.symptomSummary;
    if (s != null && s.structuredSymptoms.isNotEmpty) {
      return s.structuredSymptoms.map((x) => x.name).toList();
    }
    return _patient.symptoms;
  }

  Widget _meta(ColorScheme scheme, String label, String value) {
    final display = value.isEmpty ? 'Not reported' : value;
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notReportedRow(ColorScheme scheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not reported' : value,
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurface, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSummary(ColorScheme scheme) async {
    final current = _file?.symptomSummary.aiSummary ?? '';
    final controller = TextEditingController(text: current);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Doctor Summary',
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'The original AI summary is preserved; your version is '
                  'shown to the consultation team with your name and time.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.gutter),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  minLines: 4,
                  maxLength: 2000,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Patient reports worsening symptoms…',
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: 'Cancel',
                        height: 48,
                        backgroundColor: scheme.surfaceContainerLow,
                        foregroundColor: scheme.onSurface,
                        border: Border.all(color: scheme.outlineVariant),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: PillButton(
                        label: 'Save Summary',
                        icon: Icons.check,
                        height: 48,
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(controller.text.trim()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    setState(() => _savingSummary = true);
    try {
      final updated = await updateCaseFileSummary(
        patientId: _patientId,
        doctorSummary: result,
      );
      if (!mounted) return;
      setState(() {
        _file = updated;
        _savingSummary = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Doctor summary saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingSummary = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // -------------------------------------------------------------------------
  // AI risk / triage section (consumes the existing risk engine)
  // -------------------------------------------------------------------------

  Widget _riskCard(ColorScheme scheme) {
    final r = _file?.riskAssessment;
    final aiLevel = r?.aiTriageLevel ?? _patient.aiTriageLevel;
    final finalLevel = r?.finalTriageLevel ?? _patient.finalTriageLevel;
    final score = r?.aiRiskScore ?? _patient.aiRiskScore;
    final reason = r?.triageReason ??
        _patient.triageReason ??
        _patient.aiTriageReason ??
        'No AI assessment available.';
    final source = r?.triageSource ?? _patient.triageSource;

    return _sectionCard(
      scheme,
      icon: Icons.speed,
      iconColor: finalLevel.color,
      title: 'AI RISK ASSESSMENT',
      trailing: _sourceBadge(scheme, source),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.stackSm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RISK SCORE',
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$score',
                        style: AppTextStyles.displayHero.copyWith(
                          color: scheme.onSurface,
                          fontSize: 30,
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.stackSm),
                  decoration: BoxDecoration(
                    color: finalLevel.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: finalLevel.color.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRIAGE',
                        style: AppTextStyles.labelSm.copyWith(
                          color: finalLevel.color,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(finalLevel.icon, size: 16, color: finalLevel.color),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              finalLevel.label,
                              style: AppTextStyles.headlineMd.copyWith(
                                color: finalLevel.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        finalLevel.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(
                          color: finalLevel.color,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.stackSm),
            decoration: BoxDecoration(
              color: finalLevel.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: finalLevel.color, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REASON',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurface, fontSize: 14),
                ),
              ],
            ),
          ),
          if (finalLevel != aiLevel) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: scheme.error, width: 3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safety Escalation — AI assessed this patient as '
                      '${aiLevel.label}, but the final level was escalated to '
                      '${finalLevel.label} for urgent review.',
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_patient.doctorOverrideReason != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: scheme.primary, width: 3)),
              ),
              child: Text(
                'Doctor Override — ${_patient.doctorOverrideReason}',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          PillButton(
            label: 'Override Triage',
            icon: Icons.tune,
            height: 46,
            backgroundColor: scheme.surfaceContainerLow,
            foregroundColor: scheme.onSurface,
            border: Border.all(color: scheme.outlineVariant),
            loading: _overriding,
            onPressed: _overriding ? null : () => _openOverrideSheet(),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'AI-generated triage is an assistive assessment and does '
                  'not replace professional clinical judgment.',
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

  Widget _sourceBadge(ColorScheme scheme, TriageSource source) {
    final (icon, tint) = switch (source) {
      TriageSource.doctor => (Icons.edit, scheme.primary),
      TriageSource.safetyEscalation => (Icons.warning_amber, scheme.error),
      TriageSource.ai => (Icons.smart_toy, scheme.secondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 4),
          Text(
            source.label,
            style: AppTextStyles.labelSm.copyWith(
              color: tint,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Current vitals (interpreted server-side, with recording timestamp)
  // -------------------------------------------------------------------------

  Widget _vitalsCard(ColorScheme scheme) {
    final v = _file?.vitals;
    final items = v?.items ?? const <VitalItem>[];
    final recorded = v?.recordedLabel ?? '';

    return _sectionCard(
      scheme,
      icon: Icons.monitor_heart,
      iconColor: scheme.tertiary,
      title: 'CURRENT VITALS',
      child: items.isEmpty
          ? _notAvailable(scheme, 'No recent vitals available.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _vitalRow(scheme, items[i]),
                  if (i < items.length - 1)
                    Divider(height: 1, color: scheme.outlineVariant),
                ],
                if (recorded.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.stackSm),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Recorded at: $recorded',
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _vitalRow(ColorScheme scheme, VitalItem item) {
    final color = item.colorFor(scheme);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item.label,
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurface, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.value} ${item.unit}',
              style: AppTextStyles.bodyMd.copyWith(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (item.isAbnormal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.statusIcon, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    item.statusLabel,
                    style: AppTextStyles.labelSm.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              item.statusLabel,
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Important clinical flags (observations, never diagnoses)
  // -------------------------------------------------------------------------

  Widget _flagsCard(ColorScheme scheme) {
    final flags = _file?.flags ?? const <CaseFileFlag>[];
    return _sectionCard(
      scheme,
      icon: Icons.flag,
      iconColor: scheme.error,
      title: 'IMPORTANT FLAGS',
      child: flags.isEmpty
          ? _notAvailable(scheme, 'No flags raised for this patient.')
          : Column(
              children: [
                for (var i = 0; i < flags.length; i++) ...[
                  _flagRow(scheme, flags[i]),
                  if (i < flags.length - 1)
                    const SizedBox(height: AppSpacing.stackSm),
                ],
              ],
            ),
    );
  }

  Widget _flagRow(ColorScheme scheme, CaseFileFlag flag) {
    final color = flag.colorFor(scheme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.text,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  flag.category,
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Patient history (empty = "Not available", never fabricated)
  // -------------------------------------------------------------------------

  Widget _historyCard(ColorScheme scheme) {
    final h = _file?.history;
    final sections = [
      (
        icon: Icons.medical_information,
        color: scheme.primary,
        title: 'Chronic Conditions',
        items: h?.conditions ?? const [],
      ),
      (
        icon: Icons.medication,
        color: scheme.primary,
        title: 'Current Medications',
        items: h?.medications ?? const [],
      ),
      (
        icon: Icons.healing,
        color: scheme.tertiary,
        title: 'Allergies',
        items: h?.allergies ?? const [],
      ),
      (
        icon: Icons.family_restroom,
        color: scheme.tertiary,
        title: 'Family History',
        items: h?.familyHistory ?? const [],
      ),
      (
        icon: Icons.history,
        color: scheme.primary,
        title: 'Previous Consultations',
        items: h?.previousConsultations ?? const [],
      ),
      (
        icon: Icons.local_hospital,
        color: scheme.tertiary,
        title: 'Hospitalizations',
        items: h?.previousHospitalizations ?? const [],
      ),
      (
        icon: Icons.content_cut,
        color: scheme.tertiary,
        title: 'Surgeries',
        items: h?.previousSurgeries ?? const [],
      ),
    ];

    return _sectionCard(
      scheme,
      icon: Icons.folder_shared,
      iconColor: scheme.primary,
      title: 'PATIENT HISTORY',
      child: h == null && _file == null
          ? _notAvailable(scheme, 'No previous medical history has been recorded.')
          : Column(
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  _historyAccordion(scheme, section: sections[i]),
                  if (i < sections.length - 1)
                    const SizedBox(height: AppSpacing.unit),
                ],
              ],
            ),
    );
  }

  Widget _historyAccordion(
    ColorScheme scheme, {
    required ({
      IconData icon,
      Color color,
      String title,
      List<String> items,
    }) section,
  }) {
    final open = _expanded.contains('hist_${section.title}');
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              final key = 'hist_${section.title}';
              open ? _expanded.remove(key) : _expanded.add(key);
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.stackSm,
              ),
              child: Row(
                children: [
                  Icon(section.icon, color: section.color, size: 19),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Text(
                      section.title,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurface, fontSize: 14),
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
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: section.items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.unit),
                      child: _notAvailable(scheme, 'Not available'),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in section.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• $item',
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AI pre-consultation insights (not a diagnosis)
  // -------------------------------------------------------------------------

  Widget _insightsCard(ColorScheme scheme) {
    final i = _file?.aiInsights;
    return _sectionCard(
      scheme,
      icon: Icons.lightbulb_outline,
      iconColor: const Color(0xFFB45309),
      title: 'AI PRE-CONSULTATION INSIGHTS',
      trailing: _aiBadge(scheme, label: 'AI Generated'),
      child: i == null
          ? _notAvailable(scheme, 'No insights generated for this patient.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _insightGroup(scheme, 'KEY CONCERNS', i.keyConcerns,
                    icon: Icons.priority_high, color: scheme.error),
                const SizedBox(height: AppSpacing.stackMd),
                _insightGroup(
                    scheme, 'INFORMATION TO CLARIFY', i.informationToClarify,
                    icon: Icons.help_outline, color: scheme.primary),
                const SizedBox(height: AppSpacing.stackMd),
                _insightGroup(scheme, 'SUGGESTED REVIEW', i.suggestedReview,
                    icon: Icons.fact_check_outlined,
                    color: const Color(0xFFB45309)),
              ],
            ),
    );
  }

  Widget _insightGroup(
    ColorScheme scheme,
    String title,
    List<String> items, {
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        for (final line in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: AppTextStyles.bodyMd.copyWith(color: color)),
                Expanded(
                  child: Text(
                    line,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Case file timestamps
  // -------------------------------------------------------------------------

  Widget _timestampsCard(ColorScheme scheme) {
    final t = _file?.timestamps;
    return _sectionCard(
      scheme,
      icon: Icons.schedule,
      iconColor: scheme.onSurfaceVariant,
      title: 'CASE FILE TIMELINE',
      child: Column(
        children: [
          _timestampRow(
            scheme,
            icon: Icons.auto_awesome,
            label: 'Case file generated',
            value: t?.generatedLabel ?? '—',
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _timestampRow(
            scheme,
            icon: Icons.update,
            label: 'Last updated',
            value: t?.updatedLabel ?? '—',
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'The case file refreshes automatically when new vitals, '
                  'symptoms or risk information arrive.',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timestampRow(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurface, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Triage override (shared sheet from the queue feature)
  // -------------------------------------------------------------------------

  Future<void> _openOverrideSheet() async {
    final patient = _patient;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showTriageOverrideSheet(
      context,
      patient: patient,
      showCurrentFinal: true,
    );
    if (result == null || !mounted) return;
    setState(() => _overriding = true);
    try {
      final updated = await overridePatientTriage(
        patientId: patient.patientId,
        level: result.level,
        reason: result.reason,
      );
      if (!mounted) return;
      setState(() => _overriding = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Doctor Override — Previous: ${patient.finalTriageLevel.label} · '
            'New: ${updated.finalTriageLevel.label}',
          ),
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _overriding = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _shortWhen(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
