import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/doctor_triage_override_sheet.dart';

class DoctorPatientQueueTab extends StatefulWidget {
  const DoctorPatientQueueTab({super.key});

  @override
  State<DoctorPatientQueueTab> createState() => _DoctorPatientQueueTabState();
}

class _DoctorPatientQueueTabState extends State<DoctorPatientQueueTab> {
  static const _pollInterval = Duration(seconds: 15);

  final TextEditingController _searchController = TextEditingController();

  List<DoctorPatient> _patients = kDoctorPatients;
  QueueSummary _summary = const QueueSummary(
    red: 0,
    yellow: 0,
    green: 0,
    totalWaiting: 0,
    inConsultation: 0,
  );
  bool _loading = true;

  TriageBand? _triageFilter; // null = All
  bool _showConsulting = false; // false = Waiting, true = In Consultation
  String? _busyPatientId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final data = await fetchDoctorQueue();
      if (!mounted) return;
      setState(() {
        _patients = data.all;
        _summary = data.summary;
        _loading = false;
      });
    } catch (_) {
      // Keep the last-known queue (or the offline demo data) when the
      // backend is unreachable; the poller keeps retrying.
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  List<DoctorPatient> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _patients.where((p) {
      final matchesStatus = _showConsulting == p.isInConsultation;
      final matchesTriage =
          _triageFilter == null || p.finalTriageLevel == _triageFilter;
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.symptoms.any((s) => s.toLowerCase().contains(query));
      return matchesStatus && matchesTriage && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: null,
        title: 'Patient Queue',
        subtitle: null,
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.unit,
                  AppSpacing.containerMargin,
                  AppSpacing.stackMd,
                ),
                children: [
                  Text(
                    'Patient Queue',
                    style: AppTextStyles.displayHeroMobile
                        .copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.unit),
                  _disclaimer(scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  _summaryCards(scheme),
                  const SizedBox(height: AppSpacing.stackSm),
                  _infoChips(scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  _searchField(scheme),
                  const SizedBox(height: AppSpacing.gutter),
                  _triageFilterChips(scheme),
                  const SizedBox(height: AppSpacing.unit),
                  _statusFilterRow(scheme),
                  const SizedBox(height: AppSpacing.gutter),
                  _queueList(scheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _disclaimer(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined,
              size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI-generated triage is an assistive assessment and does not '
              'replace professional clinical judgment.',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(scheme, TriageBand.red, _summary.red),
        ),
        const SizedBox(width: AppSpacing.unit),
        Expanded(
          child: _summaryCard(scheme, TriageBand.yellow, _summary.yellow),
        ),
        const SizedBox(width: AppSpacing.unit),
        Expanded(
          child: _summaryCard(scheme, TriageBand.green, _summary.green),
        ),
      ],
    );
  }

  Widget _summaryCard(
      ColorScheme scheme, TriageBand band, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: band.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: band.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(band.icon, size: 12, color: band.color),
              const SizedBox(width: 4),
              Text(
                band.label,
                style: AppTextStyles.labelSm.copyWith(
                  color: band.color,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChips(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _infoChip(
            scheme,
            icon: Icons.schedule,
            label: 'Total Waiting: ${_summary.totalWaiting}',
          ),
        ),
        const SizedBox(width: AppSpacing.unit),
        Expanded(
          child: _infoChip(
            scheme,
            icon: Icons.videocam,
            label: 'Currently Consulting: ${_summary.inConsultation}',
          ),
        ),
      ],
    );
  }

  Widget _infoChip(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  Widget _searchField(ColorScheme scheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.gutter),
          Icon(Icons.search, color: scheme.outline),
          const SizedBox(width: AppSpacing.unit),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search patient, ID or symptom...',
                hintStyle: TextStyle(color: scheme.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _triageFilterChips(ColorScheme scheme) {
    final options = <(TriageBand?, String)>[
      (null, 'All'),
      (TriageBand.red, TriageBand.red.label),
      (TriageBand.yellow, TriageBand.yellow.label),
      (TriageBand.green, TriageBand.green.label),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _filterChip(
              scheme,
              label: options[i].$2,
              selected: _triageFilter == options[i].$1,
              band: options[i].$1,
              onTap: () => setState(() => _triageFilter = options[i].$1),
            ),
            if (i < options.length - 1) const SizedBox(width: AppSpacing.unit),
          ],
        ],
      ),
    );
  }

  Widget _statusFilterRow(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _filterChip(
            scheme,
            label: 'Waiting',
            selected: !_showConsulting,
            onTap: () => setState(() => _showConsulting = false),
          ),
        ),
        const SizedBox(width: AppSpacing.unit),
        Expanded(
          child: _filterChip(
            scheme,
            label: 'In Consultation',
            selected: _showConsulting,
            onTap: () => setState(() => _showConsulting = true),
          ),
        ),
        const SizedBox(width: AppSpacing.unit),
        Expanded(
          child: _filterChip(
            scheme,
            label: 'All Doctors',
            selected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This demo uses a single doctor. More doctors will appear '
                    'here when added to the practice.',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    ColorScheme scheme, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    TriageBand? band,
  }) {
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (band != null) ...[
                Icon(band.icon, size: 10, color: selected ? scheme.onPrimary : band.color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Queue list
  // -------------------------------------------------------------------------

  Widget _queueList(ColorScheme scheme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final patients = _filtered;
    if (patients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 36, color: scheme.outlineVariant),
              const SizedBox(height: AppSpacing.unit),
              Text(
                _showConsulting
                    ? 'No patients currently in consultation.'
                    : 'No patients match your filters.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _showConsulting
              ? 'IN CONSULTATION'
              : 'WAITING — RISK SORTED (RED → YELLOW → GREEN)',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.outline,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        for (var i = 0; i < patients.length; i++) ...[
          _patientCard(context, scheme, patients[i]),
          if (i < patients.length - 1) const SizedBox(height: AppSpacing.gutter),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Patient card
  // -------------------------------------------------------------------------

  Widget _patientCard(
      BuildContext context, ColorScheme scheme, DoctorPatient patient) {
    final band = patient.finalTriageLevel;
    return SoftCard(
      border: Border(left: BorderSide(color: band.color, width: 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _triageBadge(scheme, band),
              const SizedBox(width: AppSpacing.unit),
              if (patient.triageSource != TriageSource.ai) ...[
                _sourceChip(scheme, patient.triageSource),
                const SizedBox(width: AppSpacing.unit),
              ],
              const Spacer(),
              Icon(Icons.schedule, size: 13, color: band.color),
              const SizedBox(width: 4),
              Text(
                'Waiting: ${patient.waitTime}',
                style: AppTextStyles.labelSm.copyWith(
                  color: band.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 2),
                    Text(
                      'Age: ${patient.age} • ${patient.gender} • ${patient.id}',
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
              const SizedBox(width: AppSpacing.unit),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Risk Score: ${patient.aiRiskScore}/100',
                    style: AppTextStyles.labelSm.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (patient.aiTriageLevel != patient.finalTriageLevel)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'AI: ${patient.aiTriageLevel.label}',
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _labelLine(scheme, 'Symptoms',
              patient.symptoms.isEmpty ? '—' : patient.symptoms.join(', ')),
          const SizedBox(height: 4),
          _labelLine(
            scheme,
            'AI Reason',
            patient.triageReason ?? patient.aiTriageReason ?? '—',
          ),
          if (patient.safetyEscalated) ...[
            const SizedBox(height: AppSpacing.stackSm),
            _safetyBanner(scheme, patient),
          ],
          if (patient.doctorOverrideReason != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            _overrideBanner(scheme, patient),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          _actions(context, scheme, patient),
        ],
      ),
    );
  }

  Widget _triageBadge(ColorScheme scheme, TriageBand band) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: band.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: band.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(band.icon, size: 13, color: band.color),
          const SizedBox(width: 5),
          Text(
            band.label,
            style: AppTextStyles.labelSm.copyWith(
              color: band.color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(ColorScheme scheme, TriageSource source) {
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

  Widget _labelLine(ColorScheme scheme, String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          TextSpan(
            text: value,
            style: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _safetyBanner(ColorScheme scheme, DoctorPatient patient) {
    final critical =
        patient.criticalSymptoms.where((s) => s.isNotEmpty).toList();
    final detail = critical.isEmpty
        ? ''
        : ': ${critical.map((s) => s[0].toUpperCase() + s.substring(1)).join(', ')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: scheme.error, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Safety Escalation — flagged for urgent review$detail.',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overrideBanner(ColorScheme scheme, DoctorPatient patient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Doctor Override — ${patient.doctorOverrideReason}',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(
      BuildContext context, ColorScheme scheme, DoctorPatient patient) {
    final busy = _busyPatientId == patient.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'View Case File',
                height: 42,
                expanded: false,
                backgroundColor: scheme.surfaceContainerLowest,
                foregroundColor: scheme.secondary,
                border: Border.all(color: scheme.secondary.withValues(alpha: 0.6)),
                onPressed: () => _openCase(context, patient),
              ),
            ),
            const SizedBox(width: AppSpacing.unit),
            Expanded(
              child: PillButton(
                label: 'Override Triage',
                height: 42,
                expanded: false,
                backgroundColor: scheme.surfaceContainerLowest,
                foregroundColor: scheme.onSurface,
                border: Border.all(color: scheme.outlineVariant),
                onPressed: busy ? null : () => _openOverrideSheet(patient),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        if (patient.isWaiting)
          PillButton(
            label: 'Start Consultation',
            icon: Icons.video_call,
            height: 46,
            loading: busy,
            onPressed: busy ? null : () => _startConsultation(context, patient),
          )
        else if (patient.isInConsultation)
          PillButton(
            label: 'Complete Consultation',
            icon: Icons.check_circle_outline,
            height: 46,
            backgroundColor: scheme.surfaceContainer,
            foregroundColor: scheme.onSurface,
            loading: busy,
            onPressed: busy ? null : () => _completeConsultation(context, patient),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  void _openCase(BuildContext context, DoctorPatient patient) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DoctorPatientCaseScreen(patient: patient),
          ),
        )
        .then((_) => _load(silent: true));
  }

  Future<void> _startConsultation(
      BuildContext context, DoctorPatient patient) async {
    setState(() => _busyPatientId = patient.id);
    try {
      final updated = await startPatientConsultation(patient.patientId);
      if (!context.mounted) return;
      setState(() => _busyPatientId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consultation started for ${patient.name}.')),
      );
      await _load(silent: true);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DoctorPatientCaseScreen(patient: updated),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _busyPatientId = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _completeConsultation(
      BuildContext context, DoctorPatient patient) async {
    setState(() => _busyPatientId = patient.id);
    try {
      await completePatientConsultation(patient.patientId);
      if (!context.mounted) return;
      setState(() => _busyPatientId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consultation completed for ${patient.name}.')),
      );
      await _load(silent: true);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _busyPatientId = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openOverrideSheet(DoctorPatient patient) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showTriageOverrideSheet(context, patient: patient);
    if (result == null || !mounted) return;

    setState(() => _busyPatientId = patient.id);
    try {
      final updated = await overridePatientTriage(
        patientId: patient.patientId,
        level: result.level,
        reason: result.reason,
      );
      if (!mounted) return;
      setState(() => _busyPatientId = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Doctor Override — Previous: ${patient.finalTriageLevel.label} · '
            'New: ${updated.finalTriageLevel.label}',
          ),
        ),
      );
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyPatientId = null);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

