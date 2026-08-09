import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_prescription_preview_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/services/consultation_notes_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Doctor documentation flow: working diagnosis, AI-assisted consultation
/// summary, free-text notes, and follow-up scheduling. Every action is
/// persisted to the backend (see [ConsultationNotesService]).
class DoctorConsultationNotesScreen extends StatefulWidget {
  const DoctorConsultationNotesScreen({
    super.key,
    required this.patient,
    this.consultationId,
  });

  final DoctorPatient patient;
  final String? consultationId;

  @override
  State<DoctorConsultationNotesScreen> createState() =>
      _DoctorConsultationNotesScreenState();
}

class _DoctorConsultationNotesScreenState
    extends State<DoctorConsultationNotesScreen> {
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _summaryController = TextEditingController();
  final _followUpReasonController = TextEditingController();

  bool _busy = false;
  String _summarySource = '';
  String? _followUpInfo;
  Map<String, String> _vitals = const {};
  List<String> _symptoms = const [];

  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;
  String _consultType = 'Video Consultation';

  @override
  void initState() {
    super.initState();
    _summaryController.text = 'Tap "Generate AI Summary" to draft a clinical '
        'summary the doctor can review and edit.';
    _symptoms = widget.patient.symptoms;
    _loadPatientCase();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _summaryController.dispose();
    _followUpReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientCase() async {
    try {
      final caseData = await fetchPatientCase(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _vitals = caseData.vitals;
        if (caseData.symptoms.isNotEmpty) _symptoms = caseData.symptoms;
      });
    } catch (_) {
      // Offline / unknown patient: header-only data is enough.
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _isoTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _generateSummary() async {
    setState(() => _busy = true);
    try {
      final draft = await ConsultationNotesService.instance.generateSummary(
        patientId: widget.patient.id,
        diagnosis: _diagnosisController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      setState(() {
        _summaryController.text = draft.summary;
        _summarySource =
            draft.source == 'ai' ? 'AI-generated draft' : 'Auto-drafted';
        if (draft.followUp.isNotEmpty &&
            _followUpReasonController.text.isEmpty) {
          _followUpReasonController.text = draft.followUp;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate summary: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _followUpTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _followUpTime = picked);
  }

  Future<void> _scheduleFollowUp() async {
    final date = _followUpDate;
    final time = _followUpTime;
    if (date == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a date and time first.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final appt = await ConsultationNotesService.instance.scheduleFollowUp(
        patientId: widget.patient.id,
        doctorId: DoctorState.doctorId,
        doctorName: DoctorState.doctorName,
        date: _isoDate(date),
        time: _isoTime(time),
        reason: _followUpReasonController.text,
        consultType: _consultType,
      );
      if (!mounted) return;
      setState(() {
        _followUpInfo =
            '${appt.consultType} on ${appt.dateLabel} at ${appt.time}'
            ' · ${appt.id}';
        _followUpDate = null;
        _followUpTime = null;
        _followUpReasonController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up scheduled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule follow-up: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _busy = true);
    try {
      await ConsultationNotesService.instance.save(
        patientId: widget.patient.id,
        doctorId: DoctorState.doctorId,
        doctorName: DoctorState.doctorName,
        consultationId: widget.consultationId ?? '',
        diagnosis: _diagnosisController.text,
        notes: _notesController.text,
        vitals: _vitals,
        symptoms: _symptoms,
        aiSummary: _summaryController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation notes saved.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save notes: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Consultation Notes',
        trailingIcon: Icons.save_outlined,
        onTrailing: _busy ? null : _saveNotes,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _diagnosisField(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _aiSummaryCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _notesFieldCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _followUpCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _bottomBar(context, scheme),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(ColorScheme scheme) {
    final patient = widget.patient;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: patient.risk.color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 24),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
                Text(
                  '${patient.age.isEmpty ? '' : '${patient.age} yrs · '}'
                  '${patient.gender.isEmpty ? '' : '${patient.gender} · '}'
                  '${patient.risk.label}',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_symptoms.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_symptoms.length} sym',
                style: AppTextStyles.labelSm
                    .copyWith(color: scheme.onPrimaryContainer),
              ),
            ),
        ],
      ),
    );
  }

  Widget _diagnosisField(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKING DIAGNOSIS',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          TextField(
            controller: _diagnosisController,
            decoration: InputDecoration(
              hintText: 'e.g. Viral upper respiratory infection',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(AppSpacing.gutter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiSummaryCard(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            color: scheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Consultation Summary',
                    style: AppTextStyles.labelLg
                        .copyWith(color: scheme.onPrimaryContainer),
                  ),
                ),
                if (_summarySource.isNotEmpty)
                  Text(
                    _summarySource,
                    style: AppTextStyles.labelSm
                        .copyWith(color: scheme.onPrimaryContainer),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: TextField(
              controller: _summaryController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'AI-drafted summary appears here for you to review '
                    'and edit before saving.',
                hintStyle: AppTextStyles.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(AppSpacing.gutter),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.gutter),
            child: Row(
              children: [
                Icon(Icons.info, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'AI drafts text only; you approve the final summary.',
                    style: AppTextStyles.labelSm.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                PillButton(
                  label: 'Generate',
                  icon: Icons.auto_fix_high,
                  height: 40,
                  onPressed: _busy ? null : _generateSummary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesFieldCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DOCTOR NOTES',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Type your consultation notes here...',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(AppSpacing.gutter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_vitals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'PATIENT VITALS',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            Row(
              children: [
                Expanded(
                  child: _vitalChip(scheme, 'Temp', _vitals['temp'] ?? '--'),
                ),
                const SizedBox(width: AppSpacing.unit),
                Expanded(
                  child: _vitalChip(scheme, 'HR', _vitals['hr'] ?? '--'),
                ),
                const SizedBox(width: AppSpacing.unit),
                Expanded(
                  child: _vitalChip(scheme, 'SpO2', _vitals['spo2'] ?? '--'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _vitalChip(ColorScheme scheme, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLg.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _followUpCard(ColorScheme scheme) {
    final date = _followUpDate;
    final time = _followUpTime;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'FOLLOW-UP SCHEDULING',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: _pickTile(
                  scheme,
                  icon: Icons.calendar_today,
                  label: date == null
                      ? 'Pick date'
                      : _isoDate(date),
                  onTap: _busy ? null : _pickDate,
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: _pickTile(
                  scheme,
                  icon: Icons.schedule,
                  label: time == null ? 'Pick time' : time.format(context),
                  onTap: _busy ? null : _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          TextField(
            controller: _followUpReasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Reason for follow-up (optional)',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(AppSpacing.gutter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _consultType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Video Consultation',
                      child: Text('Video Consultation'),
                    ),
                    DropdownMenuItem(
                      value: 'Audio Consultation',
                      child: Text('Audio Consultation'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _consultType = v ?? _consultType),
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              PillButton(
                label: 'Schedule',
                icon: Icons.add_circle_outline,
                height: 48,
                onPressed: _busy ? null : _scheduleFollowUp,
              ),
            ],
          ),
          if (_followUpInfo != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.stackSm),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Scheduled: $_followUpInfo',
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pickTile(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: PillButton(
              label: 'Preview',
              icon: Icons.description_outlined,
              backgroundColor: scheme.surfaceContainerLow,
              foregroundColor: scheme.primary,
              height: 48,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      DoctorPrescriptionPreviewScreen(patient: widget.patient),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            flex: 2,
            child: PillButton(
              label: 'Save & Send to Patient',
              icon: Icons.send,
              height: 48,
              onPressed: _busy ? null : _saveNotes,
            ),
          ),
        ],
      ),
    );
  }
}
