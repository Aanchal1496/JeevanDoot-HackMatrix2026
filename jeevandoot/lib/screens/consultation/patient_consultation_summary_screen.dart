import 'package:flutter/material.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/services/consultation_notes_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/consultation_widgets.dart';

/// Patient-facing mirror of the doctor documentation: the consultation notes
/// (with the AI-assisted summary their doctor saved) and the follow-ups the
/// doctor scheduled. Read-only.
class PatientConsultationSummaryScreen extends StatefulWidget {
  const PatientConsultationSummaryScreen({super.key, this.patientId});

  final String? patientId;

  @override
  State<PatientConsultationSummaryScreen> createState() =>
      _PatientConsultationSummaryScreenState();
}

class _PatientConsultationSummaryScreenState
    extends State<PatientConsultationSummaryScreen> {
  List<ConsultationNote> _notes = const [];
  List<FollowUpAppointment> _followUps = const [];
  bool _loading = true;
  String? _error;

  String get _patientId => widget.patientId ?? AppState.patientId;

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
      final results = await Future.wait([
        ConsultationNotesService.instance.fetchPatientNotes(_patientId),
        ConsultationNotesService.instance.fetchPatientFollowUps(_patientId),
      ]);
      if (!mounted) return;
      setState(() {
        _notes = results[0].cast<ConsultationNote>();
        _followUps = results[1].cast<FollowUpAppointment>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load your consultation summary.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'My Consultation Summary',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.stackMd,
            AppSpacing.containerMargin,
            AppSpacing.stackLg,
          ),
          children: [
            if (_loading)
              const ConsultationLoading(count: 2)
            else if (_error != null)
              ConsultationError(title: _error!, onRetry: _load)
            else ...[
              Text(
                'Consultation Notes',
                style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.gutter),
              if (_notes.isEmpty)
                ConsultationEmpty(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'No consultation notes yet',
                  message:
                      'Notes and the AI summary from your doctor will appear here after a consultation.',
                )
              else ...[
                _latestNoteCard(scheme),
                if (_notes.length > 1) ...[
                  const SizedBox(height: AppSpacing.stackMd),
                  _previousNotesCard(scheme),
                ],
              ],
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Follow-up Appointments',
                style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.gutter),
              if (_followUps.isEmpty)
                ConsultationEmpty(
                  icon: Icons.event_repeat,
                  title: 'No follow-ups scheduled',
                  message:
                      'When your doctor schedules a follow-up, it will be listed here.',
                )
              else
                for (var i = 0; i < _followUps.length; i++) ...[
                  _followUpCard(scheme, _followUps[i]),
                  if (i < _followUps.length - 1)
                    const SizedBox(height: AppSpacing.gutter),
                ],
            ],
          ],
        ),
      ),
    );
  }

  // -- Notes ---------------------------------------------------------------

  Widget _latestNoteCard(ColorScheme scheme) {
    final note = _notes.first;
    return SoftCard(
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest Consultation',
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
              ),
              if (note.doctorName.isNotEmpty)
                Text(
                  note.doctorName,
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          if (note.createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(note.createdAt),
              style: AppTextStyles.labelSm
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          _label(scheme, 'DIAGNOSIS'),
          const SizedBox(height: 6),
          Text(
            note.diagnosis.isEmpty ? 'Not specified' : note.diagnosis,
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (note.aiSummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 16, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'AI Consultation Summary',
                        style: AppTextStyles.labelSm.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.aiSummary,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (note.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _label(scheme, 'DOCTOR NOTES'),
            const SizedBox(height: 6),
            Text(
              note.notes,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if (note.symptoms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            _label(scheme, 'SYMPTOMS'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in note.symptoms)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurface, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _previousNotesCard(ColorScheme scheme) {
    final older = _notes.skip(1).toList();
    return SoftCard(
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Previous Notes',
            style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          for (final note in older)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.unit),
              padding: const EdgeInsets.all(AppSpacing.stackSm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.diagnosis.isEmpty
                              ? 'Consultation note'
                              : note.diagnosis,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (note.doctorName.isNotEmpty) note.doctorName,
                            if (note.createdAt.isNotEmpty)
                              _formatDate(note.createdAt),
                          ].join(' • '),
                          style: AppTextStyles.labelSm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // -- Follow-ups ----------------------------------------------------------

  Widget _followUpCard(ColorScheme scheme, FollowUpAppointment fu) {
    final isUpcoming = _isUpcoming(fu);
    return SoftCard(
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUpcoming
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUpcoming ? Icons.event_repeat : Icons.history,
              color: isUpcoming ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fu.consultType,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fu.status,
                        style: AppTextStyles.labelSm.copyWith(
                          color: isUpcoming
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fuDate(fu)} • ${fu.time}',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
                if (fu.reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fu.reason,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isUpcoming(FollowUpAppointment fu) {
    if (fu.date.isEmpty) return true;
    try {
      return DateTime.parse(fu.date).isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  String _fuDate(FollowUpAppointment fu) =>
      fu.dateLabel.isNotEmpty ? fu.dateLabel : fu.date;

  // -- Helpers -------------------------------------------------------------

  Widget _label(ColorScheme scheme, String text) {
    return Text(
      text,
      style: AppTextStyles.labelSm.copyWith(
        color: scheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }

  /// "2026-08-09T12:34:56" (or "2026-08-09") -> "9 Aug 2026".
  String _formatDate(String iso) {
    final datePart = iso.contains('T') ? iso.split('T').first : iso;
    final parts = datePart.split('-');
    if (parts.length != 3) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) return iso;
    return '$d ${months[m - 1]} $y';
  }
}
