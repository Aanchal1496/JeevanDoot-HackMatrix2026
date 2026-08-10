import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorPatientQueueTab extends StatefulWidget {
  const DoctorPatientQueueTab({super.key});

  @override
  State<DoctorPatientQueueTab> createState() => _DoctorPatientQueueTabState();
}

class _DoctorPatientQueueTabState extends State<DoctorPatientQueueTab> {
  final DoctorService _service = DoctorService(ApiClient.instance);
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  List<DoctorPatient> _patients = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final queue = await _service.queue();
      final patients = queue.map(DoctorPatient.fromQueue).toList();
      if (mounted) {
        setState(() {
          _patients = patients;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.tr('Could not load the queue. Pull to retry.');
          _loading = false;
        });
      }
    }
  }

  List<DoctorPatient> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _patients.where((p) {
      final matchesQuery =
          query.isEmpty || p.name.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        'Urgent' => p.risk.level == DoctorRiskLevel.high ||
            p.risk.level == DoctorRiskLevel.urgent,
        'Medium' => p.risk.level == DoctorRiskLevel.medium,
        'Low' => p.risk.level == DoctorRiskLevel.low,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: null,
        title: AppStrings.tr('Patient Queue'),
        subtitle: null,
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.tr('No new notifications.'))),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.unit,
              AppSpacing.containerMargin,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr('Patient Queue'),
                  style: AppTextStyles.displayHeroMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _searchField(scheme),
                const SizedBox(height: AppSpacing.gutter),
                _filterChips(scheme),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onSurfaceVariant)),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.tr('No patients in the queue.'),
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.containerMargin,
                                0,
                                AppSpacing.containerMargin,
                                AppSpacing.stackMd,
                              ),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.gutter),
                              itemBuilder: (context, index) => _patientCard(
                                  context, scheme, _filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

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
                hintText: AppStrings.tr('Search patients...'),
                hintStyle: TextStyle(color: scheme.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(ColorScheme scheme) {
    final filters = ['All', 'Urgent', 'Medium', 'Low'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            _filterChip(scheme, filters[i]),
            if (i < filters.length - 1) const SizedBox(width: AppSpacing.unit),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(ColorScheme scheme, String label) {
    final selected = _filter == label;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => setState(() => _filter = label),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: scheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != 'All')
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: switch (label) {
                      'Urgent' => const Color(0xFFEF4444),
                      'Medium' => const Color(0xFFF59E0B),
                      _ => const Color(0xFF10B981),
                    },
                    shape: BoxShape.circle,
                  ),
                ),
              if (label != 'All') const SizedBox(width: 6),
              Text(
                AppStrings.tr(label),
                style: AppTextStyles.labelSm.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _patientCard(
      BuildContext context, ColorScheme scheme, DoctorPatient patient) {
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
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${patient.age} · ${patient.gender}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSm.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.unit),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: patient.risk.level == DoctorRiskLevel.low ||
                                  patient.risk.level == DoctorRiskLevel.medium
                              ? scheme.surfaceContainerHigh
                              : scheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 14,
                              color: patient.risk.level == DoctorRiskLevel.low ||
                                      patient.risk.level ==
                                          DoctorRiskLevel.medium
                                  ? scheme.onSurfaceVariant
                                  : scheme.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              patient.risk.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSm.copyWith(
                                color: patient.risk.level ==
                                            DoctorRiskLevel.low ||
                                        patient.risk.level ==
                                            DoctorRiskLevel.medium
                                    ? scheme.onSurface
                                    : scheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.waitTime,
                        maxLines: 1,
                        style: AppTextStyles.labelSm.copyWith(
                          color: patient.risk.color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppStrings.tr('Symptoms: '),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: patient.symptoms.join(', '),
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Align(
                alignment: Alignment.centerRight,
                child: _viewCaseButton(scheme, patient.risk),
              ),
            ],
          ),
    );
  }

  Widget _viewCaseButton(ColorScheme scheme, DoctorRisk risk) {
    final outline = risk.level == DoctorRiskLevel.low ||
        risk.level == DoctorRiskLevel.medium;
    return PillButton(
      label: AppStrings.tr('View Case'),
      expanded: false,
      backgroundColor: outline ? Colors.transparent : scheme.primary,
      foregroundColor: outline ? scheme.secondary : scheme.onPrimary,
      border: outline ? Border.all(color: scheme.secondary) : null,
      height: 44,
      onPressed: () {},
    );
  }
}
