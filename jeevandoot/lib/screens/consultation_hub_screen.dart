import 'package:flutter/material.dart';

import '../models/doctor_models.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/backend.dart';
import '../services/consultation_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import 'consultation_device_check_screen.dart';

/// Entry point for both roles: lists the upcoming tele-consultations and
/// starts the join flow (create session -> device check -> waiting room ->
/// call). Patients and doctors never book/join a room they are not assigned.
class ConsultationHubScreen extends StatefulWidget {
  const ConsultationHubScreen({super.key, required this.role});

  final String role;

  @override
  State<ConsultationHubScreen> createState() => _ConsultationHubScreenState();
}

class _ConsultationHubScreenState extends State<ConsultationHubScreen> {
  List<ConsultationAppointment> _appointments = [];
  bool _loading = true;
  String? _error;

  bool get _isDoctor => widget.role == 'doctor';

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
      final appointments = _isDoctor
          ? await _doctorAppointments()
          : await _patientAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load consultations. Please check your connection.';
      });
    }
  }

  /// Doctor side: the backend's schedule of upcoming appointments.
  Future<List<ConsultationAppointment>> _doctorAppointments() async {
    final appointments = await fetchDoctorAppointments();
    return appointments
        .where((a) => a.consultType.contains('Video') || a.consultType.contains('Audio'))
        .map((a) => ConsultationAppointment(
              id: a.id,
              name: a.name,
              doctorName: DoctorState.doctorName,
              consultType: a.consultType,
              status: a.status,
              time: a.time,
            ))
        .toList();
  }

  /// Patient side: their own appointments from /api/appointments/mine.
  Future<List<ConsultationAppointment>> _patientAppointments() async {
    final res = await ApiClient.instance.get(
      '/api/appointments/mine',
      query: {'patient_id': AppState.patientId},
    ) as Map;
    final rows = (res['appointments'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return rows
        .where((r) =>
            (r['consult_type'] ?? '').contains('Video') ||
            (r['consult_type'] ?? '').contains('Audio'))
        .map((r) => ConsultationAppointment(
              id: r['id'] as String? ?? '',
              name: r['name'] as String? ?? AppState.patientName,
              doctorName: r['doctor_name'] as String? ?? 'Dr. Priya Sharma',
              consultType: r['consult_type'] as String? ?? 'Video Consultation',
              status: r['status'] as String? ?? 'Upcoming',
              time: r['time'] as String? ?? '',
            ))
        .toList();
  }

  Future<void> _join(ConsultationAppointment appointment) async {
    if (!_isDoctor && AppState.patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to join a consultation.')),
      );
      return;
    }
    setState(() {});
    try {
      final consultation = await ConsultationApiService.instance
          .createForAppointment(
        appointmentId: appointment.id,
        requesterRole: widget.role,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConsultationDeviceCheckScreen(
            consultationId: consultation.id,
            appointmentId: appointment.id,
            role: widget.role,
            patientName: _isDoctor ? appointment.name : AppState.patientName,
            patientId: consultation.patientId,
            doctorName: _isDoctor ? DoctorState.doctorName : 'Dr. Priya Sharma',
            consultType: appointment.consultType,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start this consultation. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _appointments.where((a) => a.isUpcoming).toList();
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: _isDoctor ? 'Consultations' : 'Join Consultation',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              _isDoctor ? 'Upcoming consultations' : 'Your upcoming consultations',
              style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Join at your appointment time. The doctor and patient are the only people who can enter this room.',
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(color: scheme.error)),
                    const SizedBox(height: AppSpacing.stackMd),
                    PillButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: _load,
                    ),
                  ],
                ),
              )
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(Icons.videocam_off, size: 48, color: scheme.outline),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'No upcoming consultations',
                      style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book a consultation to see it here.',
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              for (final appointment in visible) ...[
                _appointmentCard(scheme, appointment),
                const SizedBox(height: AppSpacing.gutter),
              ],
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard(
      ColorScheme scheme, ConsultationAppointment appointment) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.videocam, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.name,
                        style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface)),
                    Text('${appointment.consultType} \u2022 ${appointment.time}',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSurfaceVariant, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          PillButton(
            label: 'Join Consultation',
            icon: Icons.video_call,
            onPressed: () => _join(appointment),
          ),
        ],
      ),
    );
  }
}
