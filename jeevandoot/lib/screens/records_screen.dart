import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/screens/prescription_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class _RecordEvent {
  const _RecordEvent({
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
  String _filter = 'All Visits';
  List<_RecordEvent> _events = const [];
  bool _loading = true;

  static const List<String> _filters = ['All Visits', 'Prescriptions', 'Reports'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await fetchRecords();
      if (!mounted) return;
      setState(() {
        _events = records.map(_recordEventFromApi).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  _RecordEvent _recordEventFromApi(RecordEvent e) {
    final isPrescription = e.type.toLowerCase().contains('prescription');
    return _RecordEvent(
      date: e.date,
      type: isPrescription ? 'Prescription' : 'Consultation',
      title: e.title.isNotEmpty ? e.title : (isPrescription ? 'Prescription' : 'Consultation'),
      detail: e.detail,
      icon: isPrescription ? Icons.medication : Icons.medical_services,
      iconBg: isPrescription
          ? AppColors.tertiaryContainer
          : AppColors.primaryContainer,
      iconColor: isPrescription
          ? AppColors.onTertiaryContainer
          : AppColors.onPrimaryContainer,
    );
  }

  List<_RecordEvent> get _visibleEvents => _filter == 'All Visits'
      ? _events
      : _events.where((e) => e.type == _filter).toList();

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
              child: Center(
                child: Text(
                  'No records found.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          for (var i = 0; i < _visibleEvents.length; i++) _timelineEvent(scheme, _visibleEvents[i], i),
          ],
        ),
      ),
    );
  }

  Widget _timelineEvent(ColorScheme scheme, _RecordEvent event, int index) {
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
                onTap: () => _openEvent(event),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.date,
                      style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.detail,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
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

  void _openEvent(_RecordEvent event) {
    if (event.type == 'Prescription') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrescriptionScreen()),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${event.title} with ${event.detail}...')),
    );
  }
}
