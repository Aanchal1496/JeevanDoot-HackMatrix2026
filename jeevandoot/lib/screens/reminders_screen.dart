import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<ReminderItem> _reminders = const [];
  final Set<String> _done = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reminders = await fetchReminders();
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  IconData _iconFor(String icon) {
    return switch (icon) {
      'medication' => Icons.medication,
      'event' => Icons.event,
      'water_drop' => Icons.water_drop,
      _ => Icons.alarm,
    };
  }

  bool _isDone(ReminderItem item) =>
      _done.contains(item.id) || item.done;

  Future<void> _markDone(ReminderItem item) async {
    setState(() => _done.add(item.id));
    try {
      await markReminderDone(item.id, done: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder marked as done.')),
      );
    } catch (_) {
      // Keep the local state; the server sync is best-effort.
    }
  }

  void _remindLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('We will remind you again shortly.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        avatarUrl: AppAssets.patientAvatar,
        title: 'JeevanDoot',
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
            Text(
              'Your Reminders',
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Stay on track with your health plan.',
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Text(
                    'No reminders yet.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              for (var i = 0; i < _reminders.length; i++) ...[
                _timelineItem(
                  scheme,
                  item: _reminders[i],
                ),
                if (i < _reminders.length - 1)
                  const SizedBox(height: AppSpacing.stackMd),
              ],
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(ColorScheme scheme, {required ReminderItem item}) {
    final done = _isDone(item);
    final active = item.active && !done;
    final icon = _iconFor(item.icon);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.time,
                    style: AppTextStyles.labelLg.copyWith(
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: active ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: active ? 20 : (done ? 16 : 12),
                  height: active ? 20 : (done ? 16 : 12),
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primaryContainer
                        : (done
                            ? scheme.primary
                            : scheme.surfaceContainerHighest),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surface,
                      width: active ? 4 : (done ? 4 : 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: active
                    ? scheme.primaryContainer.withValues(alpha: 0.05)
                    : scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? scheme.primary.withValues(alpha: 0.2)
                      : scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: active ? 48 : 40,
                        height: active ? 48 : 40,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: active ? 22 : 20,
                          color: active ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.headlineMd
                                  .copyWith(color: scheme.onSurface),
                            ),
                            Text(
                              item.subtitle,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (done)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                scheme.primaryContainer.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Taken',
                                style: AppTextStyles.labelLg
                                    .copyWith(color: scheme.primary),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (active) ...[
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: 'Mark as Done',
                            icon: Icons.check,
                            height: 48,
                            onPressed: () => _markDone(item),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.unit),
                        Expanded(
                          child: PillButton(
                            label: 'Remind Me Later',
                            height: 48,
                            backgroundColor: scheme.surfaceContainerHigh,
                            foregroundColor: scheme.onSurface,
                            onPressed: _remindLater,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
