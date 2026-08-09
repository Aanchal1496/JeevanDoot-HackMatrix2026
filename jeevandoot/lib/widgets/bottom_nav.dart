import 'package:flutter/material.dart';
import 'package:jeevandoot/theme/app_theme.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.activeIcon,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<NavItem> kNavItems = [
  NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  NavItem(
    icon: Icons.medical_services_outlined,
    activeIcon: Icons.medical_services,
    label: 'Health',
  ),
  NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Consult'),
  NavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Records'),
  NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
];

/// The fixed bottom navigation bar from the patient design system.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < kNavItems.length; i++) _item(context, i),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final item = kNavItems[index];
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
