import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/reminders_screen.dart';
import 'package:jeevandoot/services/api_client.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Prescription> _prescriptions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prescriptions = await fetchPrescriptions();
      if (!mounted) return;
      setState(() {
        _prescriptions = prescriptions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your prescriptions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'JeevanDoot',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            0,
            AppSpacing.containerMargin,
            AppSpacing.stackLg,
          ),
          children: [
            Text(
              'Your Prescriptions',
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Active and past prescriptions from your doctors.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _statusCard(
                scheme,
                icon: Icons.cloud_off,
                title: 'Could not load prescriptions',
                message: _error!,
                action: 'Retry',
                onAction: _load,
              )
            else if (_prescriptions.isEmpty)
              _statusCard(
                scheme,
                icon: Icons.medication_outlined,
                title: 'No prescriptions yet',
                message: 'Your doctors will share prescriptions here.',
              )
            else
              for (final prescription in _prescriptions)
                _prescriptionCard(scheme, prescription),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            title,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            PillButton(label: action, height: 44, onPressed: onAction),
          ],
        ],
      ),
    );
  }

  Widget _prescriptionCard(ColorScheme scheme, Prescription prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PrescriptionDetailScreen(
                prescription: prescription,
              ),
            ),
          ),
          child: Row(
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
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.doctorName,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prescription.date,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${prescription.medicines.length} medicine${prescription.medicines.length == 1 ? '' : 's'}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionDetailScreen extends StatelessWidget {
  const _PrescriptionDetailScreen({required this.prescription});

  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Prescription',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          0,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
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
                          text: prescription.doctorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' • ${prescription.date}'),
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
          for (var i = 0; i < prescription.medicines.length; i++) ...[
            _medicineCard(context, scheme, prescription.medicines[i]),
            if (i < prescription.medicines.length - 1)
              const SizedBox(height: AppSpacing.gutter),
          ],
          if (prescription.notes.isNotEmpty) ...[
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
                      prescription.notes,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medicineCard(
      BuildContext context, ColorScheme scheme, PrescriptionItem item) {
    return SoftCard(
      child: Column(
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
                      item.name,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      '${item.dosage} ${item.unit} ${item.category}',
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
                ),
                child: Text(
                  '${item.days} Days',
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
                label: 'Morning',
                value: item.morning > 0 ? '${item.morning}' : '-',
                muted: item.morning == 0,
              ),
              const SizedBox(width: 8),
              _doseCell(
                scheme,
                emoji: '🍽️',
                label: 'Afternoon',
                value: item.afternoon > 0 ? '${item.afternoon}' : '-',
                muted: item.afternoon == 0,
              ),
              const SizedBox(width: 8),
              _doseCell(
                scheme,
                emoji: '🌙',
                label: 'Night',
                value: item.night > 0 ? '${item.night}' : '-',
                muted: item.night == 0,
              ),
            ],
          ),
          if (item.instructions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.instructions,
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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
                      'Set Reminder',
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
