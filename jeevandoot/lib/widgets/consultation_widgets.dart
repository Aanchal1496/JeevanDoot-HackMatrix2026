import 'package:flutter/material.dart';
import 'package:jeevandoot/models/consultation_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Success / warning / info / danger palette used for status indicators.
/// These complement the app's teal/white healthcare palette and are only
/// used for meaningful states (never for plain unavailable slots).
class StatusColors {
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);
  static const Color neutral = Color(0xFF6B7280);
  static const Color danger = Color(0xFFEF4444);
}

/// Visual identity of an appointment status (colour + icon + label, so status
/// is never communicated by colour alone).
class StatusStyle {
  const StatusStyle(this.status, this.color, this.icon);

  final AppointmentStatus status;
  final Color color;
  final IconData icon;

  static StatusStyle of(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return const StatusStyle(AppointmentStatus.pending, StatusColors.warning, Icons.hourglass_top);
      case AppointmentStatus.upcoming:
      case AppointmentStatus.confirmed:
        return const StatusStyle(AppointmentStatus.confirmed, StatusColors.success, Icons.check_circle);
      case AppointmentStatus.inProgress:
        return const StatusStyle(AppointmentStatus.inProgress, StatusColors.info, Icons.video_call);
      case AppointmentStatus.completed:
        return const StatusStyle(AppointmentStatus.completed, StatusColors.neutral, Icons.check_circle_outline);
      case AppointmentStatus.cancelled:
        return const StatusStyle(AppointmentStatus.cancelled, StatusColors.danger, Icons.cancel);
      case AppointmentStatus.noShow:
        return const StatusStyle(AppointmentStatus.noShow, StatusColors.neutral, Icons.person_off);
    }
  }
}

/// Pill chip showing an appointment status with icon + label.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final AppointmentStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 12 : 15, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.status.label,
            style: AppTextStyles.labelSm.copyWith(
              color: style.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading used inside booking steps / lists.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Doctor card used on the doctor-selection step and in appointment cards.
class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.doctor,
    this.selected = false,
    this.onTap,
    this.onViewSlots,
    this.compact = false,
  });

  final DoctorInfo doctor;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onViewSlots;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      padding: EdgeInsets.all(compact ? AppSpacing.gutter : AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.15) : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: selected ? 0.14 : 0.06),
            blurRadius: 18,
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
              _avatar(scheme),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (doctor.qualification.isNotEmpty) doctor.qualification,
                        doctor.specialization,
                      ].join(' • '),
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _miniBadge(scheme, Icons.work_outline, doctor.experience),
                        _miniBadge(scheme, Icons.translate, doctor.languages.join(' • ')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              _miniBadge(
                scheme,
                Icons.star_rounded,
                doctor.rating.toStringAsFixed(1),
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _miniBadge(scheme, Icons.currency_rupee, doctor.feeLabel),
              const Spacer(),
              if (doctor.availableToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: StatusColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: StatusColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Available today',
                        style: AppTextStyles.labelSm.copyWith(
                          color: StatusColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!compact && onViewSlots != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            SizedBox(
              width: double.infinity,
              child: PillButton(
                label: 'View Slots',
                icon: Icons.event_available,
                height: 48,
                onPressed: onViewSlots,
              ),
            ),
          ],
        ],
      ),
    );
    return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: card);
  }

  Widget _avatar(ColorScheme scheme) {
    return ClipOval(
      child: SizedBox(
        width: 64,
        height: 64,
        child: doctor.photoUrl.isEmpty
            ? ColoredBox(color: scheme.primaryContainer.withValues(alpha: 0.4), child: const Icon(Icons.person, size: 32))
            : Image.network(
                doctor.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.surfaceContainerHigh,
                  child: const Icon(Icons.person),
                ),
              ),
      ),
    );
  }

  Widget _miniBadge(ColorScheme scheme, IconData icon, String text, {Color? color}) {
    final c = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Horizontal date chip for the schedule step.
class DateChip extends StatelessWidget {
  const DateChip({
    super.key,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final SlotDateInfo date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = date.available;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 74,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : (enabled ? scheme.surfaceContainerLowest : scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.6),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.label.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? scheme.onPrimary : (enabled ? scheme.onSurfaceVariant : scheme.outline),
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: AppTextStyles.headlineMd.copyWith(
                color: selected ? scheme.onPrimary : (enabled ? scheme.onSurface : scheme.outline),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              date.month,
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? scheme.onPrimary : (enabled ? scheme.onSurfaceVariant : scheme.outline),
              ),
            ),
            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.lock, size: 12, color: scheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

/// Time slot chip: available / selected / booked / unavailable.
class SlotChip extends StatelessWidget {
  const SlotChip({
    super.key,
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ConsultationSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = slot.status == SlotStatus.available || slot.status == SlotStatus.selected;
    final booked = slot.status == SlotStatus.booked;

    final Color bg;
    final Color fg;
    final BorderSide side;
    if (selected) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
      side = BorderSide(color: scheme.primary);
    } else if (enabled) {
      bg = scheme.surfaceContainerLowest;
      fg = scheme.onSurface;
      side = BorderSide(color: scheme.outlineVariant);
    } else {
      // Booked / unavailable: muted grey — deliberately NOT red.
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = scheme.outline;
      side = BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5));
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: side.color, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (booked) ...[
                Icon(Icons.lock, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                slot.label,
                style: AppTextStyles.labelLg.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step indicator for the 5-step booking wizard.
class ConsultationProgressHeader extends StatelessWidget {
  const ConsultationProgressHeader({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  final int currentStep;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: i <= currentStep ? scheme.primary : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: i == currentStep
                      ? scheme.primary
                      : (i < currentStep ? scheme.primaryContainer : scheme.surfaceContainerHighest),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: i < currentStep
                      ? Icon(Icons.check, size: 16, color: scheme.onPrimaryContainer)
                      : Text(
                          '${i + 1}',
                          style: AppTextStyles.labelLg.copyWith(
                            color: i == currentStep ? scheme.onPrimary : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Step ${currentStep + 1} of ${steps.length} • ${steps[currentStep]}',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Skeleton placeholder used while consultation data is loading.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

/// Full-width loading block used in booking steps.
class ConsultationLoading extends StatelessWidget {
  const ConsultationLoading({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          SkeletonCard(height: 112),
          if (i < count - 1) const SizedBox(height: AppSpacing.gutter),
        ],
      ],
    );
  }
}

/// Centered error state with a Retry action.
class ConsultationError extends StatelessWidget {
  const ConsultationError({
    super.key,
    required this.onRetry,
    this.title = 'Unable to load consultation details.',
    this.message = 'Please check your connection and try again.',
  });

  final VoidCallback onRetry;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off, color: scheme.error, size: 30),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          PillButton(
            label: 'Retry',
            icon: Icons.refresh,
            height: 48,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Centered empty state with optional CTA.
class ConsultationEmpty extends StatelessWidget {
  const ConsultationEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant, size: 30),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            PillButton(label: ctaLabel!, height: 48, onPressed: onCta),
          ],
        ],
      ),
    );
  }
}

/// Compact appointment card used in the upcoming-consultations list.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onJoin,
  });

  final ConsultationAppointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = appointment.displayStatus;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: appointment.photoUrl.isEmpty
                      ? ColoredBox(color: scheme.primaryContainer.withValues(alpha: 0.4), child: const Icon(Icons.person))
                      : Image.network(
                          appointment.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: scheme.surfaceContainerHigh, child: const Icon(Icons.person)),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      appointment.specialization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          appointment.countdownLabel,
                          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          appointment.consultType.contains('Audio') ? Icons.headphones : Icons.videocam,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.consultType,
                          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(status: status, compact: true),
            ],
          ),
          if (onJoin != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: appointment.canJoinNow ? 'Join Consultation' : appointment.joinHint.isEmpty ? 'Join Consultation' : appointment.joinHint,
                    icon: Icons.videocam,
                    height: 48,
                    backgroundColor: appointment.canJoinNow ? scheme.primary : scheme.surfaceContainerHighest,
                    foregroundColor: appointment.canJoinNow ? scheme.onPrimary : scheme.onSurfaceVariant,
                    onPressed: appointment.canJoinNow ? onJoin : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
