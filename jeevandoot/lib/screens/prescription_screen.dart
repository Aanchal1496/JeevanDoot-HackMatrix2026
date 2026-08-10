import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/patient_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/reminders_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final PatientService _service = PatientService(ApiClient.instance);
  List<Prescription> _prescriptions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.listPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final latest = _prescriptions.isEmpty ? null : _prescriptions.first;
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
            if (latest != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.tr('Your Prescription'),
                    style: AppTextStyles.displayHeroMobile
                        .copyWith(color: scheme.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 14, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          'NEW',
                          style: AppTextStyles.labelSm.copyWith(
                            color: scheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Text(
                AppStrings.tr('Your Prescription'),
                style: AppTextStyles.displayHeroMobile
                    .copyWith(color: scheme.onSurface),
              ),
            const SizedBox(height: AppSpacing.unit),
            if (_loading)
              const LinearProgressIndicator()
            else if (latest == null)
              _emptyState(scheme)
            else ...[
              _metaCard(scheme, latest),
              const SizedBox(height: AppSpacing.gutter),
              for (final medicine in latest.medicines) ...[
                _medicineCard(scheme, medicine),
                const SizedBox(height: AppSpacing.gutter),
              ],
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
                        latest.instructions?.isNotEmpty == true
                            ? latest.instructions!
                            : AppStrings.tr(
                                'Take after food. Drink plenty of water.'),
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.medication_outlined,
              size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.unit),
          Text(
            AppStrings.tr('No prescriptions yet.'),
            style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _metaCard(ColorScheme scheme, Prescription p) {
    final date = (p.createdAt ?? '').isEmpty ? '' : ' • ${p.createdAt}';
    return Container(
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
                    text: p.doctorName ?? AppStrings.tr('Doctor'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: date),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineCard(ColorScheme scheme, Medicine m) {
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
                          m.name,
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          m.dosage ?? '',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (m.duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              scheme.secondaryContainer.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        m.duration!,
                        style: AppTextStyles.labelLg
                            .copyWith(color: scheme.onSecondaryContainer),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
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
}