import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_pre_check_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorConsultTab extends StatefulWidget {
  const DoctorConsultTab({super.key});

  @override
  State<DoctorConsultTab> createState() => _DoctorConsultTabState();
}

class _DoctorConsultTabState extends State<DoctorConsultTab> {
  List<DoctorPatient> _patients = kDoctorPatients;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patients = await fetchDoctorPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients.isEmpty ? kDoctorPatients : patients;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final consultations = _patients.take(2).toList();
    return Scaffold(
      appBar: AppTopBar(
        title: 'Consult',
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                style: AppTextStyles.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (consultations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: Text(
                      'No patients in the queue right now.',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                for (var i = 0; i < consultations.length; i++) ...[
                  _consultCard(
                    context,
                    scheme,
                    patient: consultations[i],
                    isActive: i == 0,
                  ),
                  if (i < consultations.length - 1)
                    const SizedBox(height: AppSpacing.gutter),
                ],
            ],
          ),
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
