import 'package:flutter/material.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/services/prescription_i18n.dart';
import 'package:jeevandoot/services/prescription_store.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Shared visual identity: category icon + colour for a medicine.
class MedicineVisuals {
  const MedicineVisuals(this.icon, this.color);

  final IconData icon;
  final Color color;

  static MedicineVisuals of(String category, ColorScheme scheme) {
    final c = category.toLowerCase();
    if (c.contains('syrup') || c.contains('liquid')) {
      return MedicineVisuals(Icons.local_drink, const Color(0xFFF59E0B));
    }
    if (c.contains('capsule')) {
      return MedicineVisuals(Icons.medication_liquid, const Color(0xFF7C3AED));
    }
    if (c.contains('injection') || c.contains('vaccine')) {
      return MedicineVisuals(Icons.vaccines, const Color(0xFF2563EB));
    }
    if (c.contains('drop')) {
      return MedicineVisuals(Icons.water_drop, const Color(0xFF0284C7));
    }
    return MedicineVisuals(Icons.medication, scheme.primary);
  }
}

const List<String> kRxPeriods = ['morning', 'afternoon', 'night'];

/// Default clock times used for reminders / next-dose hints.
const Map<String, String> kPeriodTimes = {
  'morning': '08:00',
  'afternoon': '14:00',
  'night': '21:00',
};

IconData kPeriodIcon(String period) => switch (period) {
      'morning' => Icons.wb_sunny,
      'afternoon' => Icons.wb_twilight,
      _ => Icons.nights_stay,
    };

/// Computes the display date ("15 Aug") a medicine is taken until.
String? untilDateLabel(String? dateIso, int days) {
  if (dateIso == null || dateIso.isEmpty || days <= 0) return null;
  final base = DateTime.tryParse(dateIso);
  if (base == null) return null;
  final until = base.add(Duration(days: days));
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${until.day} ${months[until.month - 1]}';
}

/// Large icon-based medicine card.
class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.item,
    required this.s,
    required this.dateIso,
    required this.reminder,
    required this.onReminderChanged,
  });

  final PrescriptionItem item;
  final RxStrings s;
  final String dateIso;
  final MedicineReminder? reminder;
  final ValueChanged<MedicineReminder> onReminderChanged;

  String _periodCount(String period) {
    final v = switch (period) {
      'morning' => item.morning,
      'afternoon' => item.afternoon,
      _ => item.night,
    };
    return v > 0 ? '$v' : '0';
  }

  bool _hasPeriod(String period) => switch (period) {
        'morning' => item.morning > 0,
        'afternoon' => item.afternoon > 0,
        _ => item.night > 0,
      };

  String get _foodLabel {
    final i = item.instructions.toLowerCase();
    if (i.contains('before')) return s.beforeFood;
    if (i.contains('after')) return s.afterFood;
    return s.anytime;
  }

  String get _nextDoseLabel {
    if (!_hasPeriod('morning') && !_hasPeriod('afternoon') && !_hasPeriod('night')) {
      return s.nextDoseTomorrow;
    }
    final now = DateTime.now();
    for (final period in kRxPeriods) {
      if (!_hasPeriod(period)) continue;
      final hhmm = kPeriodTimes[period]!;
      final parts = hhmm.split(':');
      final time = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (time.isAfter(now)) {
        final label = switch (period) {
          'morning' => s.morning,
          'afternoon' => s.afternoon,
          _ => s.night,
        };
        return '${s.nextDose}: $label';
      }
    }
    return '${s.nextDose}: ${s.nextDoseTomorrow}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = MedicineVisuals.of(item.category, scheme);
    final unit = s.unitWord(item.category);
    final until = untilDateLabel(dateIso, item.days);
    final totalPerDay = item.morning + item.afternoon + item.night;

    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -- Medicine header ------------------------------------------------
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 28),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: scheme.onSurface,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.dosage} ${item.unit}',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medication, size: 15, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${item.days} ${s.forDays.replaceAll('{n}', '').trim()}'
                          .replaceAll(RegExp(r'\s+'), ' ')
                          .trim(),
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),

          // -- Dosage ----------------------------------------------------------
          _labeledRow(
            scheme,
            label: s.dosage,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 24),
                ),
                const SizedBox(width: AppSpacing.unit),
                Text(
                  '1 $unit',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: scheme.onSurface,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          // -- Timing ----------------------------------------------------------
          Row(
            children: [
              for (final period in kRxPeriods) ...[
                Expanded(
                  child: _timingCell(scheme, period),
                ),
                if (period != kRxPeriods.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),

          // -- Food + duration ---------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  scheme,
                  icon: Icons.restaurant,
                  iconColor: const Color(0xFFEA580C),
                  label: s.food,
                  value: _foodLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _infoTile(
                  scheme,
                  icon: Icons.calendar_today_outlined,
                  iconColor: scheme.primary,
                  label: s.duration,
                  value: s.forDays.replaceAll('{n}', '${item.days}'),
                  extra: until == null ? null : s.until.replaceAll('{date}', until),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
            child: Divider(height: 1, color: scheme.surfaceContainerHighest),
          ),

          // -- Reminder -----------------------------------------------------------
          _reminderRow(scheme, unit, totalPerDay),
        ],
      ),
    );
  }

  Widget _labeledRow(ColorScheme scheme,
      {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: AppSpacing.stackSm),
      ],
    );
  }

  Widget _timingCell(ColorScheme scheme, String period) {
    final active = _hasPeriod(period);
    final count = _periodCount(period);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            kPeriodIcon(period),
            color: active ? scheme.primary : scheme.outline,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            switch (period) {
              'morning' => s.morning,
              'afternoon' => s.afternoon,
              _ => s.night,
            },
            style: AppTextStyles.labelSm.copyWith(
              color: active ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Text(
              count,
              style: AppTextStyles.labelLg.copyWith(
                color: active ? scheme.onPrimary : scheme.outline,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    ColorScheme scheme, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? extra,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 2),
            Text(
              extra,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reminderRow(
      ColorScheme scheme, String unit, int totalPerDay) {
    final enabled = reminder?.enabled ?? false;
    final time = reminder?.time ?? kPeriodTimes['morning']!;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled
                ? scheme.tertiaryContainer.withValues(alpha: 0.4)
                : scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            enabled ? Icons.notifications_active : Icons.notifications_none,
            color: enabled ? scheme.tertiary : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    s.setReminder,
                    style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: enabled
                          ? scheme.tertiaryContainer
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      enabled ? s.reminderOn : s.reminderOff,
                      style: AppTextStyles.labelSm.copyWith(
                        color: enabled
                            ? scheme.onTertiaryContainer
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                enabled
                    ? '${s.reminderTime}: ${_formatTime(time)} • $_nextDoseLabel'
                    : s.nextDose,
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: (v) => onReminderChanged(MedicineReminder(
                enabled: v,
                time: v ? time : '08:00',
              )),
          activeThumbColor: scheme.tertiary,
        ),
      ],
    );
  }

  static String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;
    final ap = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $ap';
  }
}

/// "Today's Medicines" timeline with per-dose taken tracking.
class TodayMedicinesSection extends StatelessWidget {
  const TodayMedicinesSection({
    super.key,
    required this.medicines,
    required this.s,
    required this.dateKey,
    required this.taken,
    required this.onToggleTaken,
  });

  final List<PrescriptionItem> medicines;
  final RxStrings s;
  final String dateKey;
  final Set<String> taken;
  final void Function(PrescriptionItem item, String period) onToggleTaken;

  bool _isTaken(PrescriptionItem item, String period) =>
      taken.contains('$dateKey|${item.name}|$period');

  List<PrescriptionItem> _forPeriod(String period) => medicines
      .where((m) => switch (period) {
            'morning' => m.morning > 0,
            'afternoon' => m.afternoon > 0,
            _ => m.night > 0,
          })
      .toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final any = medicines.any((m) =>
        m.morning > 0 || m.afternoon > 0 || m.night > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.today, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              s.todaysMedicines,
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        if (!any)
          Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              s.noPrescriptionsHint,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          )
        else
          for (final period in kRxPeriods)
            if (_forPeriod(period).isNotEmpty) ...[
              _periodHeader(scheme, period),
              const SizedBox(height: AppSpacing.stackSm),
              for (final item in _forPeriod(period)) ...[
                _doseRow(scheme, item, period),
                const SizedBox(height: AppSpacing.unit),
              ],
              const SizedBox(height: AppSpacing.stackSm),
            ],
      ],
    );
  }

  Widget _periodHeader(ColorScheme scheme, String period) {
    final color = switch (period) {
      'morning' => const Color(0xFFF59E0B),
      'afternoon' => const Color(0xFF0284C7),
      _ => const Color(0xFF6366F1),
    };
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(kPeriodIcon(period), color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.unit),
        Text(
          switch (period) {
            'morning' => s.morning,
            'afternoon' => s.afternoon,
            _ => s.night,
          },
          style: AppTextStyles.labelLg.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _doseRow(ColorScheme scheme, PrescriptionItem item, String period) {
    final takenDone = _isTaken(item, period);
    final unit = s.unitWord(item.category);
    final count = switch (period) {
      'morning' => item.morning,
      'afternoon' => item.afternoon,
      _ => item.night,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: takenDone
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            takenDone ? Icons.check_circle : Icons.medication,
            color: takenDone ? const Color(0xFF10B981) : scheme.primary,
            size: 26,
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$count $unit',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: takenDone
                ? const Color(0xFF10B981)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => onToggleTaken(item, period),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      takenDone ? Icons.check : Icons.check_circle_outline,
                      size: 18,
                      color: takenDone ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      takenDone ? s.taken : s.markAsTaken,
                      style: AppTextStyles.labelSm.copyWith(
                        color: takenDone ? scheme.onPrimary : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
