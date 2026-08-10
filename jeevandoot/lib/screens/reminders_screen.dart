import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final Set<String> _done = {'8am'};

  void _markDone(String id) {
    setState(() => _done.add(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.tr('Reminder marked as done.'))),
    );
  }

  void _remindLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.tr('We will remind you again shortly.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        avatarUrl: AppAssets.patientAvatar,
        title: AppStrings.tr('JeevanDoot'),
        onTrailing: () => openOfflineScreen(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        children: [
          Text(
            AppStrings.tr('Your Reminders'),
            style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            AppStrings.tr('Stay on track with your health plan.'),
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          _timelineItem(
            scheme,
            time: '8:00 AM',
            active: false,
            done: _done.contains('8am'),
            icon: Icons.medication,
            title: AppStrings.tr('Paracetamol'),
            subtitle: AppStrings.tr('1 tablet • After Breakfast'),
            badge: _done.contains('8am') ? AppStrings.tr('Taken') : null,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _timelineItem(
            scheme,
            time: '10:00 AM',
            active: true,
            done: _done.contains('10am'),
            icon: Icons.event,
            title: AppStrings.tr('Doctor Follow-up'),
            subtitle: AppStrings.tr('August 13 • Dr. Sharma Clinic'),
            actions: true,
            onDone: () => _markDone('10am'),
            onLater: _remindLater,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _timelineItem(
            scheme,
            time: '2:00 PM',
            active: false,
            done: false,
            icon: Icons.water_drop,
            title: AppStrings.tr('Hydration Goal'),
            subtitle: AppStrings.tr('Drink 2 glasses of water'),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    ColorScheme scheme, {
    required String time,
    required bool active,
    required bool done,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    bool actions = false,
    VoidCallback? onDone,
    VoidCallback? onLater,
  }) {
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
                    time,
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
                        : (done ? scheme.primary : scheme.surfaceContainerHighest),
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
                              title,
                              style: AppTextStyles.headlineMd
                                  .copyWith(color: scheme.onSurface),
                            ),
                            Text(
                              subtitle,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.2),
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
                                badge,
                                style: AppTextStyles.labelLg
                                    .copyWith(color: scheme.primary),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (actions) ...[
                    const SizedBox(height: AppSpacing.stackMd),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: AppStrings.tr('Mark as Done'),
                            icon: Icons.check,
                            height: 48,
                            onPressed: done ? null : onDone,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.unit),
                        Expanded(
                          child: PillButton(
                            label: AppStrings.tr('Remind Me Later'),
                            height: 48,
                            backgroundColor: scheme.surfaceContainerHigh,
                            foregroundColor: scheme.onSurface,
                            onPressed: onLater,
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
