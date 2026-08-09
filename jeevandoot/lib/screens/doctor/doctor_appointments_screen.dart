import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorAppointmentsTab extends StatefulWidget {
  const DoctorAppointmentsTab({super.key});

  @override
  State<DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<DoctorAppointmentsTab> {
  String _tab = 'Today';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Schedule',
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Appointments',
                  style: AppTextStyles.displayHeroMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _dateSelector(scheme),
                const SizedBox(height: AppSpacing.stackMd),
                _tabs(scheme),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                0,
                AppSpacing.containerMargin,
                AppSpacing.stackMd,
              ),
              itemCount: kDoctorAppointments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.gutter),
              itemBuilder: (context, index) => _appointmentCard(
                context,
                scheme,
                kDoctorAppointments[index],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSelector(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: scheme.onSurfaceVariant,
            onPressed: () {},
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Today, 24 Oct',
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
                Text(
                  '5 Appointments',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: scheme.onSurfaceVariant,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _tabs(ColorScheme scheme) {
    final tabs = ['Today', 'Upcoming', 'Completed'];
    return Row(
      children: [
        for (final tab in tabs)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = tab),
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == tab
                          ? scheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLg.copyWith(
                    color: _tab == tab ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _appointmentCard(
      BuildContext context, ColorScheme scheme, DoctorAppointment appointment) {
    final completed = appointment.status == 'Completed';
    final riskColors = switch (appointment.risk.level) {
      DoctorRiskLevel.low => (bar: const Color(0xFF22C55E), badge: const Color(0xFFDCFCE7), text: const Color(0xFF15803D)),
      DoctorRiskLevel.medium => (bar: const Color(0xFFFACC15), badge: const Color(0xFFFEF9C3), text: const Color(0xFFA16207)),
      _ => (bar: const Color(0xFFEF4444), badge: const Color(0xFFFEE2E2), text: const Color(0xFFB91C1C)),
    };
    return Opacity(
      opacity: completed ? 0.75 : 1,
      child: SoftCard(
        border: Border(
          left: BorderSide(color: riskColors.bar, width: 4),
        ),
        onTap: () {},
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
                        appointment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMd
                            .copyWith(color: scheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${appointment.id} • ${appointment.status}',
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
                    Text(
                      appointment.time,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: completed
                            ? scheme.surfaceContainerHighest
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        appointment.status,
                        maxLines: 1,
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                Icon(Icons.videocam,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    appointment.consultType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColors.badge,
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: riskColors.bar.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '● ${appointment.risk.label}',
                    style: AppTextStyles.labelSm.copyWith(
                      color: riskColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            if (completed)
              _outlineButton(scheme, 'View Notes', onTap: () {})
            else
              Row(
                children: [
                  Expanded(
                    child: _outlineButton(
                      scheme,
                      'View Case',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DoctorPatientCaseScreen(
                            patient: kDoctorPatients.first,
                          ),
                        ),
                      ),
                      color: scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: _filledButton(scheme, 'Start Consultation',
                        onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorPatientCaseScreen(
                                  patient: kDoctorPatients.first,
                                ),
                              ),
                            )),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton(ColorScheme scheme, String label,
      {required VoidCallback onTap, Color? color}) {
    return PillButton(
      label: label,
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: color ?? scheme.onSurfaceVariant,
      border: Border.all(color: color ?? scheme.outlineVariant),
      height: 48,
      onPressed: onTap,
    );
  }

  Widget _filledButton(ColorScheme scheme, String label,
      {required VoidCallback onTap}) {
    return PillButton(
      label: label,
      height: 48,
      onPressed: onTap,
    );
  }
}
