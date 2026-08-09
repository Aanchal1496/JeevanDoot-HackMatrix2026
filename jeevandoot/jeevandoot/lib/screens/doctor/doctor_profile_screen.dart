import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorProfileTab extends StatelessWidget {
  const DoctorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: AppAssets.doctorAvatar,
        subtitle: 'Profile',
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _profileHeader(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _detailsCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _stats(scheme),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              AppAssets.doctorAvatar,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  ColoredBox(color: scheme.surfaceContainerHigh),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  DoctorState.doctorName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 20, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DoctorState.specialization,
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          PillButton(
            label: 'Edit Profile',
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editing coming soon.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Details',
            style: AppTextStyles.labelLg.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _detailRow(
            scheme,
            icon: Icons.badge_outlined,
            label: 'MEDICAL REGISTRATION ID',
            value: DoctorState.registrationId,
          ),
          const SizedBox(height: AppSpacing.gutter),
          _detailRow(
            scheme,
            icon: Icons.medical_services,
            label: 'SPECIALIZATION',
            value: 'Internal Medicine, General Practice',
          ),
          const SizedBox(height: AppSpacing.gutter),
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackSm),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: scheme.primary),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DoctorState.workingHours,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DoctorState.workingDays,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.outline,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats(ColorScheme scheme) {
    final stats = [
      (icon: Icons.group, color: scheme.secondary, value: '1.2k+', label: 'Total Patients'),
      (icon: Icons.star, color: scheme.primary, value: '4.9', label: 'Rating'),
      (icon: Icons.workspace_premium, color: scheme.tertiary, value: '8 Yrs', label: 'Experience'),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(stats[i].icon, color: stats[i].color, size: 28),
                  const SizedBox(height: AppSpacing.unit),
                  Text(
                    stats[i].value,
                    style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                  ),
                  Text(
                    stats[i].label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSm.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
          ),
          if (i < stats.length - 1) const SizedBox(width: AppSpacing.unit),
        ],
      ],
    );
  }
}
