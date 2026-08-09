import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/screens/timeline_event_detail_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Personal health records / visit timeline: every consultation visit,
/// prescription and health record the patient has, newest first.
class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  String _filter = 'All Visits';
  List<TimelineEvent> _events = const [];
  bool _loading = true;

  static const List<String> _filters = [
    'All Visits',
    'Consultations',
    'Prescriptions',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final events = await fetchTimeline();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<TimelineEvent> get _visibleEvents => switch (_filter) {
        'Consultations' =>
          _events.where((e) => e.isConsultation).toList(),
        'Prescriptions' =>
          _events.where((e) => e.isPrescription).toList(),
        'Reports' => _events.where((e) => e.type == 'record').toList(),
        _ => _events,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: AppAssets.patientAvatar,
        subtitle: 'My Health',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              'My Health',
              style: AppTextStyles.displayHeroMobile.copyWith(
                color: scheme.onPrimaryFixedVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Your personal health records & visit timeline',
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = _filter == filter;
                  return InkWell(
                    onTap: () => setState(() => _filter = filter),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: selected
                            ? null
                            : Border.all(color: scheme.outlineVariant),
                      ),
                      child: Center(
                        child: Text(
                          filter,
                          style: AppTextStyles.labelLg.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_visibleEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 40, color: scheme.outline),
                    const SizedBox(height: AppSpacing.gutter),
                    Text(
                      'No records found.',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < _visibleEvents.length; i++)
                _timelineEvent(scheme, _visibleEvents[i], i),
          ],
        ),
      ),
    );
  }

  Widget _timelineEvent(ColorScheme scheme, TimelineEvent event, int index) {
    final isLast = index == _visibleEvents.length - 1;
    final icon = event.isConsultation
        ? Icons.medical_services
        : (event.isPrescription ? Icons.medication : Icons.folder_outlined);
    final iconBg = event.isConsultation
        ? AppColors.primaryContainer
        : (event.isPrescription
            ? AppColors.tertiaryContainer
            : scheme.surfaceContainerHigh);
    final iconColor = event.isConsultation
        ? AppColors.onPrimaryContainer
        : (event.isPrescription
            ? AppColors.onTertiaryContainer
            : scheme.onSurfaceVariant);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: scheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.stackMd),
              child: SoftCard(
                onTap: () => _openEvent(event),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.date,
                            style: AppTextStyles.labelLg
                                .copyWith(color: scheme.primary),
                          ),
                        ),
                        Text(
                          event.type.toUpperCase(),
                          style: AppTextStyles.labelSm
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style:
                          AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.subtitle.isNotEmpty
                                ? event.subtitle
                                : event.detail,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (event.subtitle.isNotEmpty && event.detail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.detail,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEvent(TimelineEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimelineEventDetailScreen(event: event),
      ),
    );
  }
}
