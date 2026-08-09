import 'package:flutter/material.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Detail view for one entry in the personal health record / visit timeline:
/// a consultation (diagnosis + AI summary + doctor notes), a prescription
/// (medicines + follow-up), or a generic health record.
class TimelineEventDetailScreen extends StatelessWidget {
  const TimelineEventDetailScreen({super.key, required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: event.isConsultation
            ? 'Visit Details'
            : (event.isPrescription ? 'Prescription' : 'Health Record'),
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
            if (event.isConsultation)
              _consultation(scheme)
            else if (event.isPrescription)
              _prescription(scheme)
            else
              _record(scheme),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    final d = event.data;
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.isConsultation
                  ? Icons.medical_services
                  : (event.isPrescription ? Icons.medication : Icons.folder_outlined),
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.subtitle.isNotEmpty ? event.subtitle : 'Health record',
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  event.date,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (d['consultation_id'] != null && (d['consultation_id'] as String).isNotEmpty)
            Text(
              '${d['consultation_id']}',
              style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  // -- Consultation ---------------------------------------------------------

  Widget _consultation(ColorScheme scheme) {
    final d = event.data;
    final symptoms = (d['symptoms'] as List?)?.cast<String>() ?? const [];
    final vitals = (d['vitals'] as Map?)?.cast<String, String>() ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(scheme),
        const SizedBox(height: AppSpacing.stackMd),
        _card(scheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(scheme, 'WORKING DIAGNOSIS'),
                const SizedBox(height: 6),
                Text(
                  (d['diagnosis'] as String? ?? '').isEmpty
                      ? 'Not specified'
                      : d['diagnosis'] as String,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )),
        if ((d['ai_summary'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackMd),
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
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
                  d['ai_summary'] as String,
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
        if ((d['notes'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackMd),
          _card(scheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(scheme, 'DOCTOR NOTES'),
                  const SizedBox(height: 6),
                  Text(
                    d['notes'] as String,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onSurface,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              )),
        ],
        if (symptoms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackMd),
          _card(scheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(scheme, 'SYMPTOMS'),
                  const SizedBox(height: AppSpacing.unit),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in symptoms)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s,
                            style: AppTextStyles.bodyMd.copyWith(
                                color: scheme.onSurface, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ],
              )),
        ],
        if (vitals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackMd),
          _card(scheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(scheme, 'VITALS'),
                  const SizedBox(height: AppSpacing.unit),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in vitals.entries)
                        if (entry.value.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: scheme.outlineVariant),
                            ),
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: scheme.onSurface, fontSize: 13),
                            ),
                          ),
                    ],
                  ),
                ],
              )),
        ],
      ],
    );
  }

  // -- Prescription ---------------------------------------------------------

  Widget _prescription(ColorScheme scheme) {
    final d = event.data;
    final medicines =
        (d['medicines'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final followUpDate = d['follow_up_date'] as String? ?? '';
    final followUpTime = d['follow_up_time'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(scheme),
        const SizedBox(height: AppSpacing.stackMd),
        for (final m in medicines) ...[
          _card(scheme,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.medication,
                        size: 20, color: scheme.onTertiaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name'] as String? ?? '',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _dosageLabel(m),
                          style: AppTextStyles.bodyMd.copyWith(
                              color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                        if ((m['instructions'] as String? ?? '').isNotEmpty)
                          Text(
                            m['instructions'] as String,
                            style: AppTextStyles.labelSm.copyWith(
                                color: scheme.primary),
                          ),
                      ],
                    ),
                  ),
                  if ((m['days'] as int? ?? 0) > 0)
                    Text(
                      '${m['days']} days',
                      style: AppTextStyles.labelSm
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              )),
          const SizedBox(height: AppSpacing.gutter),
        ],
        if ((d['notes'] as String? ?? '').isNotEmpty) ...[
          _card(scheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(scheme, 'NOTES'),
                  const SizedBox(height: 6),
                  Text(
                    d['notes'] as String,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurface, fontSize: 14),
                  ),
                ],
              )),
          const SizedBox(height: AppSpacing.stackMd),
        ],
        if (followUpDate.isNotEmpty)
          _card(scheme,
              child: Row(
                children: [
                  Icon(Icons.event_repeat, color: scheme.primary),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Follow-up scheduled',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          followUpTime.isNotEmpty
                              ? '$followUpDate • $followUpTime'
                              : followUpDate,
                          style: AppTextStyles.bodyMd.copyWith(
                              color: scheme.onSurfaceVariant, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
      ],
    );
  }

  String _dosageLabel(Map<String, dynamic> m) {
    final dosage = m['dosage'] as String? ?? '';
    final unit = m['unit'] as String? ?? '';
    if (dosage.isEmpty) return '';
    return unit.isEmpty ? dosage : '$dosage $unit';
  }

  // -- Generic record -------------------------------------------------------

  Widget _record(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(scheme),
        const SizedBox(height: AppSpacing.stackMd),
        _card(scheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(scheme, 'DETAILS'),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.detail,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant, fontSize: 14),
                  ),
                ],
              ],
            )),
      ],
    );
  }

  // -- Helpers --------------------------------------------------------------

  Widget _card(ColorScheme scheme, {required Widget child}) {
    return SoftCard(
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      child: child,
    );
  }

  Widget _label(ColorScheme scheme, String text) {
    return Text(
      text,
      style: AppTextStyles.labelSm.copyWith(
        color: scheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}
