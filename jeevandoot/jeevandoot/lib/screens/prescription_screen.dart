import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/reminders_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: AppStrings.tr('JeevanDoot'),
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          0,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.tr('Your Prescription'),
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: scheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.tr('Dr. Priya Sharma'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: AppStrings.tr(' • August 10, 2026')),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            _medicineCard(context, scheme),
            const SizedBox(height: AppSpacing.gutter),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: scheme.outline, size: 20),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: Text(
                      AppStrings.tr('Take after food. Drink plenty of water.'),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medicineCard(BuildContext context, ColorScheme scheme) {
    return SoftCard(
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('💊', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr('Paracetamol'),
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          AppStrings.tr('500 mg Tablet'),
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      AppStrings.tr('3 Days'),
                      style: AppTextStyles.labelLg
                          .copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              Row(
                children: [
                  _doseCell(
                    scheme,
                    emoji: '☀️',
                    label: AppStrings.tr('Morning'),
                    value: AppStrings.tr('1'),
                    muted: false,
                  ),
                  const SizedBox(width: 8),
                  _doseCell(
                    scheme,
                    emoji: '🍽️',
                    label: AppStrings.tr('Afternoon'),
                    value: '-',
                    muted: true,
                  ),
                  const SizedBox(width: 8),
                  _doseCell(
                    scheme,
                    emoji: '🌙',
                    label: AppStrings.tr('Night'),
                    value: AppStrings.tr('1'),
                    muted: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.unit),
              Material(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: AppSpacing.touchTargetMin,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primaryContainer.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alarm,
                          color: scheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.tr('Set Reminder'),
                          style: AppTextStyles.labelLg
                              .copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doseCell(
    ColorScheme scheme, {
    required String emoji,
    required String label,
    required String value,
    required bool muted,
  }) {
    final bg = muted ? scheme.surfaceContainerLowest : scheme.surface;
    final fg = muted ? scheme.onSurfaceVariant : scheme.onSurface;
    final valueBg = muted ? scheme.surfaceContainerHighest : scheme.primary;
    final valueFg = muted ? scheme.onSurfaceVariant : scheme.onPrimary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: muted ? 0.1 : 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelLg.copyWith(
                color: fg,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: valueBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  color: valueFg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
