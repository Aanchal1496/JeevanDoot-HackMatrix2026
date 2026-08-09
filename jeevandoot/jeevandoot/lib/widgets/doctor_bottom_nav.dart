import 'package:flutter/material.dart';
import 'package:jeevandoot/theme/app_theme.dart';

class DoctorNavItem {
  const DoctorNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<DoctorNavItem> kDoctorNavItems = [
  DoctorNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  DoctorNavItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Patients'),
  DoctorNavItem(
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    label: 'Schedule',
  ),
  DoctorNavItem(
    icon: Icons.medical_services_outlined,
    activeIcon: Icons.medical_services,
    label: 'Consult',
  ),
  DoctorNavItem(icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle, label: 'Profile'),
];

/// Bottom navigation bar for the doctor-facing app (mirrors doctor.html).
class DoctorBottomNavBar extends StatelessWidget {
  const DoctorBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < kDoctorNavItems.length; i++) _item(context, i),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final item = kDoctorNavItems[index];
    final selected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 24,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTextStyles.labelSm.copyWith(
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
