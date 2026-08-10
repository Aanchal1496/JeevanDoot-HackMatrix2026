import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/asha_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/asha/asha_assignment_detail_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class AshaHomeScreen extends StatefulWidget {
  const AshaHomeScreen({super.key});

  @override
  State<AshaHomeScreen> createState() => _AshaHomeScreenState();
}

class _AshaHomeScreenState extends State<AshaHomeScreen> {
  final AshaService _service = AshaService(ApiClient.instance);

  List<AshaAssignment> _assignments = const [];
  List<AshaTask> _tasks = const [];
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
      final assignments = await _service.assignments();
      final tasks = await _service.tasks();
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _tasks = tasks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.tr('Could not load your area. Pull to retry.');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pendingCount = _tasks.where((t) => t.status == 'pending').length;
    return Scaffold(
      appBar: AppTopBar(
        subtitle: AppStrings.tr('Village Health Worker'),
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          children: [
            Text(
              AppStrings.tr('ASHA Dashboard'),
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onPrimaryFixedVariant),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Row(
              children: [
                _statCard(scheme, Icons.group_outlined, _assignments.length,
                    AppStrings.tr('Assigned\nfamilies'), scheme.primaryContainer),
                const SizedBox(width: AppSpacing.gutter),
                _statCard(scheme, Icons.pending_actions, pendingCount,
                    AppStrings.tr('Pending\ntasks'), scheme.tertiaryContainer),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              AppStrings.tr('MY AREA'),
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.unit),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.stackLg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Text(_error!,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant)),
              )
            else if (_assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Text(AppStrings.tr('No families assigned to you.'),
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant)),
              )
            else
              for (final a in _assignments) _assignmentCard(scheme, a),
          ],
        ),
      ),
    );
  }

  Widget _statCard(ColorScheme scheme, IconData icon, int value, String label,
      Color bg) {
    return Expanded(
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: bg),
            const SizedBox(height: 4),
            Text('$value', style: AppTextStyles.headlineLg),
            Text(label,
                style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _assignmentCard(ColorScheme scheme, AshaAssignment a) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AshaAssignmentDetailScreen(assignment: a),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.patientName ?? AppStrings.tr('Patient'),
                    style: AppTextStyles.headlineMd
                        .copyWith(color: scheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  '${a.village ?? 'Village'} · Patient #${a.patientUserId}',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}