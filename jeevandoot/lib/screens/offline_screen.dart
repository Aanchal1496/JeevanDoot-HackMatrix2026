import 'package:flutter/material.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'JeevanDoot',
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checking connection...')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.secondary.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.cloud_off,
                size: 64,
                color: scheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              "You're offline",
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              "Your information will be saved on this device and synced when you're connected again.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _statusTile(
              scheme,
              icon: Icons.check_circle,
              color: scheme.primaryContainer,
              title: 'Symptoms saved',
              subtitle: 'Stored securely on your phone.',
            ),
            const SizedBox(height: AppSpacing.unit),
            _statusTile(
              scheme,
              icon: Icons.folder_special,
              color: scheme.primaryContainer,
              title: 'Health records',
              subtitle: 'Available for offline viewing.',
            ),
            const SizedBox(height: AppSpacing.unit),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: scheme.tertiaryContainer,
                    width: 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync,
                      color: scheme.tertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2 items waiting to sync',
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          'Will update automatically later.',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              height: 192,
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.landscape,
                size: 64,
                color: scheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile(
    ColorScheme scheme, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
