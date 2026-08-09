import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_appointments_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_consult_tab.dart';
import 'package:jeevandoot/screens/doctor/doctor_new_prescription_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_queue_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_profile_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/doctor_bottom_nav.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DoctorDashboardTab(
            onOpenQueue: () => setState(() => _currentIndex = 1),
            onOpenAppointments: () => setState(() => _currentIndex = 2),
          ),
          const DoctorPatientQueueTab(),
          const DoctorAppointmentsTab(),
          const DoctorConsultTab(),
          const DoctorProfileTab(),
        ],
      ),
      bottomNavigationBar: DoctorBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class DoctorDashboardTab extends StatefulWidget {
  const DoctorDashboardTab({
    super.key,
    required this.onOpenQueue,
    required this.onOpenAppointments,
  });

  final VoidCallback onOpenQueue;
  final VoidCallback onOpenAppointments;

  @override
  State<DoctorDashboardTab> createState() => _DoctorDashboardTabState();
}

class _DoctorDashboardTabState extends State<DoctorDashboardTab> {
  DoctorStats? _stats;
  DoctorPatient? _urgentCase;
  DoctorAppointment? _nextConsultation;
  final DoctorPatient _fallbackPatient = kDoctorPatients.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await fetchDoctorStats();
      final urgent = await fetchUrgentCase();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _urgentCase = urgent;
      });
    } catch (_) {
      // Fall back to the seeded demo values when offline.
    }
    try {
      final appointments = await fetchDoctorAppointments();
      if (!mounted) return;
      final next = appointments.where((a) => a.status != 'Completed').firstOrNull;
      setState(() => _nextConsultation = next);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: AppAssets.doctorAvatar,
        subtitle: DoctorState.specialization,
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _greeting(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _statsGrid(scheme),
            if (_urgentCase != null) ...[
              const SizedBox(height: AppSpacing.stackMd),
              _urgentCaseCard(context, scheme),
            ],
            if (_nextConsultation != null) ...[
              const SizedBox(height: AppSpacing.stackMd),
              _nextConsultationCard(context, scheme),
            ],
            const SizedBox(height: AppSpacing.stackMd),
            _quickActions(context, scheme),
          ],
        ),
      ),
    );
  }

  Widget _greeting(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, ${DoctorState.doctorName.replaceFirst('Dr. ', 'Dr. ')} 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.displayHeroMobile
                    .copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                DoctorState.specialization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.unit),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Available',
                style: AppTextStyles.labelSm.copyWith(
                  color: const Color(0xFF15803D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsGrid(ColorScheme scheme) {
    final stats = _stats;
    final rows = [
      (label: 'Patients', value: stats?.patients ?? '0', color: scheme.onSurface),
      (label: 'Waiting', value: stats?.waiting ?? '0', color: scheme.secondary),
      (label: 'Urgent', value: stats?.urgent ?? '0', color: scheme.error),
      (label: 'Completed', value: stats?.completed ?? '0', color: scheme.primary),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Overview",
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.outline,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Row(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Expanded(child: _statCard(scheme, rows[i].label, rows[i].value, rows[i].color)),
              if (i < rows.length - 1) const SizedBox(width: AppSpacing.unit),
            ],
          ],
        ),
      ],
    );
  }

  Widget _statCard(ColorScheme scheme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headlineMd.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgentCaseCard(BuildContext context, ColorScheme scheme) {
    final patient = _urgentCase!;
    final caseTarget = patient;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: scheme.error, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.error.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'URGENT',
                style: AppTextStyles.labelLg.copyWith(
                  color: scheme.error,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.warning_amber_rounded, color: scheme.error),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            patient.name,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          Text(
            '${patient.age} · ${patient.gender}',
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackSm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.symptoms.join(', '),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: scheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'Waiting: ${patient.waitTime.toLowerCase().replaceFirst(' wait', '')}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  scheme,
                  label: 'View Case File',
                  filled: false,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DoctorPatientCaseScreen(patient: caseTarget),
                  )),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _actionButton(
                  scheme,
                  label: 'Start Consultation',
                  filled: true,
                  backgroundColor: scheme.error,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DoctorPatientCaseScreen(patient: caseTarget),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextConsultationCard(BuildContext context, ColorScheme scheme) {
    final next = _nextConsultation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT CONSULTATION',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.outline,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: const Color(0xFFFBBF24), width: 4),
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
                          next.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 16, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                next.time,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              next.risk.label,
                              style: AppTextStyles.labelSm.copyWith(
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(next.consultType.contains('Video')
                                ? Icons.videocam
                                : Icons.mic, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              next.consultType.contains('Video') ? 'Video' : 'Audio',
                              style: AppTextStyles.labelSm.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              _actionButton(
                scheme,
                label: 'View Appointment',
                filled: false,
                textColor: scheme.secondary,
                borderColor: scheme.secondary,
                onTap: widget.onOpenAppointments,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context, ColorScheme scheme) {
    final caseTarget = _urgentCase ?? _fallbackPatient;
    final actions = [
      (
        icon: Icons.group,
        color: scheme.primary,
        bg: scheme.primaryContainer.withValues(alpha: 0.2),
        label: 'Patients',
        onTap: widget.onOpenQueue,
      ),
      (
        icon: Icons.calendar_month,
        color: scheme.secondary,
        bg: scheme.secondaryContainer.withValues(alpha: 0.2),
        label: 'Appointments',
        onTap: widget.onOpenAppointments,
      ),
      (
        icon: Icons.medical_services,
        color: scheme.tertiary,
        bg: scheme.tertiaryContainer.withValues(alpha: 0.2),
        label: 'Start Consultation',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DoctorPatientCaseScreen(patient: caseTarget),
        )),
      ),
      (
        icon: Icons.medication,
        color: scheme.primary,
        bg: scheme.primaryContainer.withValues(alpha: 0.2),
        label: 'Prescriptions',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DoctorNewPrescriptionScreen(patient: caseTarget),
        )),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.outline,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.gutter,
            crossAxisSpacing: AppSpacing.gutter,
            mainAxisExtent: 152,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Material(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: action.bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _actionButton(
    ColorScheme scheme, {
    required String label,
    required VoidCallback onTap,
    bool filled = true,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
  }) {
    return PillButton(
      label: label,
      backgroundColor: filled
          ? (backgroundColor ?? scheme.primary)
          : scheme.surfaceContainerLowest,
      foregroundColor:
          filled ? scheme.onPrimary : (textColor ?? scheme.onSurface),
      border: filled ? null : Border.all(color: borderColor ?? scheme.outline),
      height: 48,
      onPressed: onTap,
    );
  }
}
