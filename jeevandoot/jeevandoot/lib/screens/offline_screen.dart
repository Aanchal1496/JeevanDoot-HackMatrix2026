import 'package:flutter/material.dart';
import 'package:jeevandoot/services/sync_queue.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  final SyncQueue _queue = SyncQueue.instance;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _queue.init();
    _queue.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    _queue.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    await _queue.syncNow();
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _queue.status;
    final count = _queue.pendingCount;

    final (IconData icon, Color iconColor, String title, String subtitle) =
        switch (status) {
      SyncStatus.online => (
          Icons.cloud_done,
          scheme.primary,
          'You\'re online',
          count == 0
              ? 'Everything is up to date.'
              : '$count item(s) waiting to sync.',
        ),
      SyncStatus.syncing => (
          Icons.sync,
          scheme.primary,
          'Syncing…',
          'Uploading queued changes.',
        ),
      SyncStatus.synced => (
          Icons.check_circle,
          const Color(0xFF10B981),
          'All synced',
          'Queued changes are uploaded.',
        ),
      SyncStatus.failed => (
          Icons.error_outline,
          scheme.error,
          'Some items failed',
          'Check your connection and try again.',
        ),
      SyncStatus.offline => (
          Icons.cloud_off,
          scheme.secondary,
          'You\'re offline',
          count == 0
              ? 'Your changes will be saved on this device and synced later.'
              : '$count item(s) saved and waiting to sync.',
        ),
    };

    return Scaffold(
      appBar: AppTopBar(showBack: true, title: 'JeevanDoot', onTrailing: () {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.stackMd),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.secondary.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              title,
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            if (_syncing)
              const LinearProgressIndicator()
            else
              PillButton(
                label: count == 0 ? 'Check Connection' : 'Sync Now',
                icon: Icons.sync,
                expanded: false,
                height: 48,
                onPressed: _sync,
              ),
            const SizedBox(height: AppSpacing.stackLg),
            if (count > 0) ...[
              Text(
                'QUEUED ITEMS',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              for (final op in _queue.pending) _queueCard(scheme, op),
              const SizedBox(height: AppSpacing.unit),
              if (status == SyncStatus.failed && _queue.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.unit),
                  child: Text(
                    _queue.lastError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.error, fontSize: 13),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _queueCard(ColorScheme scheme, PendingOp op) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.unit),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              op.method.toUpperCase() == 'PUT'
                  ? Icons.edit
                  : Icons.cloud_upload_outlined,
              color: scheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${op.method.toUpperCase()} ${op.path}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLg
                        .copyWith(color: scheme.onSurface)),
                Text(
                  'Queued ${_relative(op.createdAt)}',
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relative(String? iso) {
    final t = DateTime.tryParse(iso ?? '');
    if (t == null) return 'just now';
    final diff = DateTime.now().difference(t.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}