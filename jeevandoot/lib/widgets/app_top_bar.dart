import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/offline_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';

/// Header used across the patient app. Mirrors the HTML `TopAppBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.avatarUrl,
    this.subtitle,
    this.title = 'JeevanDoot',
    this.trailingIcon = Icons.cloud_off,
    this.onTrailing,
    this.hideTrailing = false,
    this.leadingIcon,
    this.onLeading,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final String? avatarUrl;
  final String? subtitle;
  final String title;
  final IconData trailingIcon;
  final VoidCallback? onTrailing;
  final bool hideTrailing;
  final IconData? leadingIcon;
  final VoidCallback? onLeading;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.touchTargetMin);

  Widget _leading(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (showBack || onBack != null || leadingIcon != null) {
      return _iconButton(
        context,
        icon: leadingIcon ?? Icons.arrow_back,
        onTap: onLeading ??
            onBack ??
            () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
        color: scheme.onSurfaceVariant,
      );
    }
    if (avatarUrl != null) {
      return ClipOval(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
            color: scheme.surfaceContainerHighest,
          ),
          child: _AvatarImage(avatarUrl: avatarUrl!),
        ),
      );
    }
    return Icon(Icons.account_circle, color: scheme.primary, size: 28);
  }

  Widget _title(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headlineLgMobile.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 14, color: scheme.onSurfaceVariant),
              Flexible(
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final centered = subtitle == null;
    return Container(
      height: AppSpacing.touchTargetMin,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Center(child: _leading(context)),
          ),
          Expanded(
            child: centered
                ? Center(child: _title(context))
                : _title(context),
          ),
          SizedBox(
            width: 56,
            child: Center(
              child: hideTrailing
                  ? null
                  : _iconButton(context, icon: trailingIcon, onTap: onTrailing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap ??
          () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color ?? scheme.primary, size: 24),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.person),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Icon(Icons.person, color: AppColors.onSurfaceVariant);
      },
    );
  }
}

/// Convenience: opens the offline status screen.
void openOfflineScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const OfflineScreen()),
  );
}
