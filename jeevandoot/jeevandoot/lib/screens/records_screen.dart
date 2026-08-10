import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/patient_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class _RecordEntry {
  const _RecordEntry({
    required this.date,
    required this.type,
    required this.title,
    required this.detail,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String date;
  final String type;
  final String title;
  final String detail;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final PatientService _service = PatientService(ApiClient.instance);

  String _filter = 'All';
  static const List<String> _filters = ['All', 'Prescriptions', 'Reports', 'Vitals'];

  List<_RecordEntry> _entries = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scheme = Theme.of(context).colorScheme;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prescriptions = await _service.listPrescriptions();
      final records = await _service.listHealthRecords();
      final vitals = await _service.listVitals();
      final List<_RecordEntry> entries = [
        for (final p in prescriptions)
          _RecordEntry(
            date: _formatDate(p.createdAt),
            type: 'Prescriptions',
            title: 'Prescription · ${p.diagnosis}',
            detail: '${p.doctorName ?? AppStrings.tr('Doctor')} · ${p.medicines.length} medicine(s)\n${p.instructions ?? ''}',
            icon: Icons.medication,
            iconBg: scheme.tertiaryContainer,
            iconColor: scheme.onTertiaryContainer,
          ),
        for (final r in records)
          _RecordEntry(
            date: _formatDate(r.createdAt),
            type: 'Reports',
            title: r.title,
            detail: '${r.recordType}\n${r.description ?? ''}',
            icon: Icons.description,
            iconBg: scheme.secondaryContainer,
            iconColor: scheme.onSecondaryContainer,
          ),
        for (final v in vitals)
          _RecordEntry(
            date: _formatDate(v.recordedAt),
            type: 'Vitals',
            title: AppStrings.tr('Vitals recorded'),
            detail: [
              if (v.bloodPressure != null) 'BP ${v.bloodPressure}',
              if (v.pulse != null) 'Pulse ${v.pulse}',
              if (v.oxygenSaturation != null) 'SpO₂ ${v.oxygenSaturation}%',
              if (v.temperature != null) 'Temp ${v.temperature}°C',
              if (v.weight != null) 'Wt ${v.weight}kg',
            ].join(' · '),
            icon: Icons.favorite,
            iconBg: scheme.primaryContainer,
            iconColor: scheme.onPrimaryContainer,
          ),
      ];
      entries.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.tr('Could not load your records. Pull to retry.');
          _loading = false;
        });
      }
    }
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    final months = [
      AppStrings.tr('Jan'),
      AppStrings.tr('Feb'),
      AppStrings.tr('Mar'),
      AppStrings.tr('Apr'),
      AppStrings.tr('May'),
      AppStrings.tr('Jun'),
      AppStrings.tr('Jul'),
      AppStrings.tr('Aug'),
      AppStrings.tr('Sep'),
      AppStrings.tr('Oct'),
      AppStrings.tr('Nov'),
      AppStrings.tr('Dec'),
    ];
    return '${t.day} ${months[t.month - 1]}, ${t.year}';
  }

  List<_RecordEntry> get _visibleEvents =>
      _filter == 'All' ? _entries : _entries.where((e) => e.type == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        subtitle: AppStrings.tr('My Health'),
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              AppStrings.tr('My Health'),
              style: AppTextStyles.displayHeroMobile.copyWith(
                color: scheme.onPrimaryFixedVariant,
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
                          AppStrings.tr(filter),
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
                padding: EdgeInsets.all(AppSpacing.stackLg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Center(
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else if (_visibleEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Center(
                  child: Text(
                    AppStrings.tr('No records here yet.'),
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            for (var i = 0; i < _visibleEvents.length; i++)
              _timelineEvent(scheme, _visibleEvents[i], i),
          ],
        ),
      ),
    );
  }

  Widget _timelineEvent(ColorScheme scheme, _RecordEntry event, int index) {
    final isLast = index == _visibleEvents.length - 1;
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
                  color: event.iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(event.icon, size: 20, color: event.iconColor),
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
                onTap: () => _openDetail(event),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.date,
                      style:
                          AppTextStyles.labelLg.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.detail,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(_RecordEntry event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title,
                style: AppTextStyles.headlineLg
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.stackMd),
            Text(event.detail,
                style: AppTextStyles.bodyLg
                    .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}