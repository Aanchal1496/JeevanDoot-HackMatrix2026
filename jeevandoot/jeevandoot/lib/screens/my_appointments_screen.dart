import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/patient_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final _service = PatientService(ApiClient.instance);
  late Future<List<AppointmentItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listAppointments();
  }

  Future<void> _reload() {
    setState(() {
      _future = _service.listAppointments();
    });
    return _future;
  }

  Future<void> _cancel(AppointmentItem a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text('This appointment will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.put('/appointments/${a.id}/cancel', const {});
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not cancel appointment.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(title: 'My Appointments', showBack: true),
      body: FutureBuilder<List<AppointmentItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load appointments.'),
                  const SizedBox(height: 12),
                  PillButton(label: 'Retry', onPressed: _reload),
                ],
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No appointments yet. Book a consultation to get started.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (context, i) {
              final a = items[i];
              final cancelled = a.status?.toLowerCase() == 'cancelled';
              return SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(a.type?.toLowerCase().contains('video') == true
                            ? Icons.videocam
                            : Icons.mic),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.type ?? 'Consultation',
                            style: AppTextStyles.headlineMd
                                .copyWith(color: scheme.onSurface),
                          ),
                        ),
                        _statusPill(scheme, a.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Scheduled: ${a.scheduledAt ?? '—'}',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (!cancelled) ...[
                      const SizedBox(height: AppSpacing.stackSm),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () => _cancel(a),
                          child: const Text('Cancel appointment'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusPill(ColorScheme scheme, String? status) {
    final s = status?.toLowerCase();
    final label = s == 'cancelled'
        ? 'Cancelled'
        : s == 'completed'
            ? 'Completed'
            : s ?? 'Confirmed';
    final color = s == 'cancelled'
        ? scheme.error
        : s == 'completed'
            ? scheme.primary
            : scheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.labelLg.copyWith(color: color)),
    );
  }
}

