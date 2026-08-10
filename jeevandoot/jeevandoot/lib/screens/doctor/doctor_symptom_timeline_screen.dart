import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';

class DoctorSymptomTimelineScreen extends StatelessWidget {
  const DoctorSymptomTimelineScreen({super.key, required this.patient});

  final DoctorPatient patient;

  static const _timeline = [
    (
      date: 'Day 1 · 08:30 AM',
      title: 'Fever reported',
      detail: 'Patient reported fever of 100.4°F (38°C) after waking up.',
      type: 'symptom',
    ),
    (
      date: 'Day 1 · 11:00 AM',
      title: 'Cough developed',
      detail: 'Dry persistent cough started, worsening through the day.',
      type: 'symptom',
    ),
    (
      date: 'Day 2 · 09:00 AM',
      title: 'Vitals updated',
      detail: 'Temperature 101°F, pulse 92 bpm, SpO2 96%.',
      type: 'vital',
    ),
    (
      date: 'Day 2 · 06:30 PM',
      title: 'Breathing difficulty',
      detail: 'Patient reported mild breathing difficulty on exertion.',
      type: 'symptom',
    ),
    (
      date: 'Day 3 · 08:00 AM',
      title: 'Consultation booked',
      detail: 'Patient booked a video consultation with Dr. Priya Sharma.',
      type: 'event',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: AppStrings.tr('Symptom Timeline'),
        hideTrailing: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        children: [
          _headerCard(scheme),
          const SizedBox(height: AppSpacing.stackMd),
          for (var i = 0; i < _timeline.length; i++) ...[
            _timelineItem(scheme, index: i, entry: _timeline[i]),
            if (i < _timeline.length - 1)
              Container(
                width: 2,
                height: AppSpacing.stackSm,
                margin: const EdgeInsets.only(left: 12),
                color: scheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }

  Widget _headerCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timeline, size: 24, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: AppTextStyles.labelLg
                      .copyWith(color: scheme.onPrimaryContainer),
                ),
                Text(
                  AppStrings.tr('Timeline of reported symptoms and events'),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    ColorScheme scheme, {
    required int index,
    required ({
      String date,
      String title,
      String detail,
      String type,
    }) entry,
  }) {
    final isVital = entry.type == 'vital';
    final isEvent = entry.type == 'event';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isVital
                ? scheme.tertiary
                : isEvent
                    ? scheme.secondary
                    : scheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 3),
          ),
          child: Icon(
            isVital
                ? Icons.monitor_heart
                : isEvent
                    ? Icons.event_available
                    : Icons.report,
            size: 13,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.unit),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.tr(entry.title),
                        style: AppTextStyles.labelLg
                            .copyWith(color: scheme.onSurface),
                      ),
                    ),
                    Text(
                      AppStrings.tr(entry.date),
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tr(entry.detail),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
