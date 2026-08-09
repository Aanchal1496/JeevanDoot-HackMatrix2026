import 'package:flutter/material.dart';
import 'package:jeevandoot/models/consultation_models.dart';
import 'package:jeevandoot/screens/video_call_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/consultation_widgets.dart';

/// Full details of a booked consultation.
class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final ConsultationAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = appointment;
    final status = appointment.displayStatus;
    final isAudio = a.consultType.contains('Audio');

    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Appointment',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consultation Details',
                  style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
                ),
                StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: a.photoUrl.isEmpty
                              ? ColoredBox(
                                  color: scheme.primaryContainer.withValues(alpha: 0.4),
                                  child: const Icon(Icons.person, size: 32),
                                )
                              : Image.network(
                                  a.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => ColoredBox(
                                    color: scheme.surfaceContainerHigh,
                                    child: const Icon(Icons.person),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.doctorName,
                              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                            ),
                            Text(
                              [a.qualification, a.specialization]
                                  .where((e) => e.isNotEmpty)
                                  .join(' • '),
                              style: AppTextStyles.bodyMd.copyWith(color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  _detailRow(scheme, Icons.calendar_today, 'Date',
                      a.start == null ? a.dateLabel : '${a.start!.day} ${_months[a.start!.month - 1]} ${a.start!.year}'),
                  _detailRow(scheme, Icons.schedule, 'Time', a.time),
                  _detailRow(
                    scheme,
                    isAudio ? Icons.mic : Icons.videocam,
                    'Consultation',
                    a.consultType,
                  ),
                  _detailRow(scheme, Icons.currency_rupee, 'Fee', a.fee <= 0 ? 'Free' : '₹${a.fee.round()}'),
                  if (a.reason.isNotEmpty) _detailRow(scheme, Icons.notes, 'Reason', a.reason),
                  if (a.attachments.isNotEmpty)
                    _detailRow(
                      scheme,
                      Icons.attach_file,
                      'Attachments',
                      a.attachments
                          .map((x) => '${x.name} (${x.sizeLabel})')
                          .join(', '),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(scheme, Icons.confirmation_number, 'Booking ID', a.id),
                  if (a.meetingId.isNotEmpty)
                    _detailRow(scheme, Icons.video_call, 'Meeting ID', a.meetingId),
                  _detailRow(
                    scheme,
                    a.isAshaBooked ? Icons.support_agent : Icons.person,
                    'Booked via',
                    a.isAshaBooked ? 'ASHA Worker' : 'Self booking',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (status == AppointmentStatus.cancelled ||
                status == AppointmentStatus.noShow)
              Container(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: scheme.error),
                    const SizedBox(width: AppSpacing.unit),
                    Expanded(
                      child: Text(
                        status == AppointmentStatus.cancelled
                            ? 'This consultation was cancelled. The time slot has been released.'
                            : 'The patient did not join this consultation.',
                        style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PillButton(
                    label: a.canJoinNow
                        ? 'Join Consultation'
                        : (a.joinHint.isEmpty ? 'Join Consultation' : a.joinHint),
                    icon: Icons.videocam,
                    backgroundColor: a.canJoinNow ? scheme.primary : scheme.surfaceContainerHighest,
                    foregroundColor: a.canJoinNow ? scheme.onPrimary : scheme.onSurfaceVariant,
                    onPressed: a.canJoinNow
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  doctorName: a.doctorName,
                                  specialization: a.specialization,
                                  photoUrl: a.photoUrl,
                                  meetingId: a.meetingId,
                                  isAudioOnly: isAudio,
                                ),
                              ),
                            )
                        : null,
                  ),
                  if (!a.canJoinNow && a.joinHint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.unit),
                      child: Text(
                        'Join available ${a.joinWindowMinutes} minutes before the appointment.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Widget _detailRow(ColorScheme scheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.secondary),
          const SizedBox(width: AppSpacing.gutter),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
