import 'package:flutter/material.dart';

import '../models/doctor_models.dart';
import '../services/consultation_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'doctor/doctor_consultation_notes_screen.dart';

/// Shown after the call ends: duration + quality summary, then (for the
/// doctor) the existing consultation-notes flow for the medical summary.
class ConsultationCompletedScreen extends StatefulWidget {
  const ConsultationCompletedScreen({
    super.key,
    required this.consultationId,
    required this.role,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.duration,
    required this.qualityLabel,
    required this.peerLeftEarly,
  });

  final String consultationId;
  final String role;
  final String patientName;
  final String patientId;
  final String doctorName;
  final Duration duration;
  final String qualityLabel;
  final bool peerLeftEarly;

  @override
  State<ConsultationCompletedScreen> createState() =>
      _ConsultationCompletedScreenState();
}

class _ConsultationCompletedScreenState
    extends State<ConsultationCompletedScreen> {
  bool _saving = true;
  String? _error;

  bool get _isDoctor => widget.role == 'doctor';

  @override
  void initState() {
    super.initState();
    _saveRecord();
  }

  Future<void> _saveRecord() async {
    try {
      await ConsultationApiService.instance.end(
        consultationId: widget.consultationId,
        durationSeconds: widget.duration.inSeconds,
        connectionQuality: widget.qualityLabel,
      );
    } catch (_) {
      // The record is best-effort; never block the user on it.
      if (mounted) setState(() => _error = 'Could not save the consultation record.');
    }
    if (mounted) setState(() => _saving = false);
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m == 0) return '$s sec';
    return '$m min $s sec';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final patient = DoctorPatient(
      name: widget.patientName,
      id: widget.patientId,
      age: '',
      gender: '',
      risk: const DoctorRisk(DoctorRiskLevel.medium, 'Medium'),
      symptoms: const [],
      waitTime: '00 MIN WAIT',
    );
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, size: 52, color: Color(0xFF16A34A)),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Consultation Completed',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                widget.peerLeftEarly
                    ? 'The other participant ended the consultation.'
                    : 'Thank you for using JeevanDoot teleconsultation.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    _row(scheme, 'Duration', _fmtDuration(widget.duration)),
                    const Divider(height: 24),
                    _row(scheme, 'Connection quality', widget.qualityLabel),
                    if (_error != null) ...[
                      const Divider(height: 24),
                      _row(scheme, 'Record', _error!),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              if (!_saving) ...[
                if (_isDoctor)
                  PillButton(
                    label: 'Write Consultation Summary',
                    icon: Icons.edit_note,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorConsultationNotesScreen(
                          patient: patient,
                          consultationId: widget.consultationId,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.gutter),
                PillButton(
                  label: 'Done',
                  icon: Icons.home_outlined,
                  backgroundColor: scheme.surfaceContainerLow,
                  foregroundColor: scheme.onSurface,
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ColorScheme scheme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant)),
        Text(value,
            style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
