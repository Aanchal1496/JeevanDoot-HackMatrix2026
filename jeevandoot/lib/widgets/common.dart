import 'package:flutter/material.dart';
import 'package:jeevandoot/theme/app_theme.dart';

/// Animated pulsing ring around a child, matching the `.pulse-animation`
/// used throughout the patient UI.
class PulsingRing extends StatefulWidget {
  const PulsingRing({
    super.key,
    required this.child,
    this.color,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final Color? color;
  final Duration duration;

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _scale = Tween<double>(begin: 0.9, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.35),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              transform: Matrix4.diagonal3Values(_scale.value, _scale.value, 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: _opacity.value),
                  width: 3,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// A soft, rounded card with the standard shadow used across the app.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.gutter),
    this.color,
    this.radius = 16,
    this.border,
    this.onTap,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = color ?? scheme.surfaceContainerLowest;
    final shadow = shadowColor ?? scheme.primary.withValues(alpha: 0.08);
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: border,
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A pill-shaped primary action button matching `.rounded-full` buttons.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = AppSpacing.touchTargetMin,
    this.border,
    this.shadowColor,
    this.expanded = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final BoxBorder? border;
  final Color? shadowColor;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primary;
    final fg = foregroundColor ?? scheme.onPrimary;
    final content = [
      if (loading)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: fg,
            ),
          ),
        )
      else ...[
        if (icon != null) Icon(icon, color: fg, size: 22),
      ],
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelLg.copyWith(color: fg),
        ),
      ),
    ];
    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: border,
            boxShadow: shadowColor != null
                ? [
                    BoxShadow(
                      color: shadowColor!,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: content,
          ),
        ),
      ),
    );
    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
