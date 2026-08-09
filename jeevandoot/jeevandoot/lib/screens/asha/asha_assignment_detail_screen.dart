import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/asha_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class AshaAssignmentDetailScreen extends StatefulWidget {
  const AshaAssignmentDetailScreen({super.key, required this.assignment});

  final AshaAssignment assignment;

  @override
  State<AshaAssignmentDetailScreen> createState() =>
      _AshaAssignmentDetailScreenState();
}

class _AshaAssignmentDetailScreenState extends State<AshaAssignmentDetailScreen> {
  final AshaService _service = AshaService(ApiClient.instance);
  bool _busy = false;

  void _run(Future<void> Function() fn, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = widget.assignment;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(showBack: true, title: 'Patient', hideTrailing: true),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.patientName ?? 'Patient',
                    style: AppTextStyles.headlineLg
                        .copyWith(color: scheme.onSurface)),
                const SizedBox(height: 4),
                Text('${a.village ?? 'Village'} · Patient #${a.patientUserId}',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _actionTile(
            scheme,
            icon: Icons.monitor_heart_outlined,
            color: scheme.primary,
            title: 'Record Vitals',
            subtitle: 'Enter BP, temperature, pulse, SpO₂',
            onTap: () => _run(_recordVitals, 'Vitals recorded.'),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _actionTile(
            scheme,
            icon: Icons.healing_outlined,
            color: scheme.tertiary,
            title: 'Assisted Symptom Entry',
            subtitle: 'Run a guided symptom check',
            onTap: () => _run(_assist, 'Assessment submitted.'),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _actionTile(
            scheme,
            icon: Icons.local_hospital_outlined,
            color: scheme.error,
            title: 'Escalate to Doctor',
            subtitle: 'Submit an urgent referral',
            onTap: () => _run(_escalate, 'Case escalated.'),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(ColorScheme scheme,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: scheme.onPrimary),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelLg
                          .copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 2),
Text(subtitle,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _recordVitals() async {
    final bp = await _promptText('Blood pressure', hint: 'e.g. 120/80');
    if (!mounted || bp == null) return;
    final temp = await _promptText('Temperature (°C)', hint: 'e.g. 98.6');
    if (!mounted || temp == null) return;
    final pulse = await _promptText('Pulse (bpm)', hint: 'e.g. 72');
    if (!mounted || pulse == null) return;
    final spo2 = await _promptText('SpO₂ (%)', hint: 'e.g. 98');
    if (!mounted || spo2 == null) return;
    final bpText = bp;
    final tempText = temp;
    final pulseText = pulse;
    final spo2Text = spo2;
    await _service.recordVitals(
      widget.assignment.patientUserId,
      {
        'blood_pressure': bpText.isEmpty ? null : bpText,
        'temperature': tempText.isEmpty ? null : double.tryParse(tempText),
        'pulse': pulseText.isEmpty ? null : int.tryParse(pulseText),
        'oxygen_saturation': spo2Text.isEmpty ? null : double.tryParse(spo2Text),
      },
    );
  }

  Future<void> _assist() async {
    final text = await _promptText('Describe the patient\'s symptoms',
        hint: 'e.g. fever and cough since two days');
    if (!mounted || text == null || text.trim().isEmpty) return;
    final trimmed = text.trim();
    await _service.assist(
      widget.assignment.patientUserId,
      {'text': trimmed},
    );
  }

  Future<void> _escalate() async {
    final reason = await _promptText('Reason for escalation',
        hint: 'Why does this need urgent review?', multiline: true);
    if (!mounted || reason == null || reason.trim().isEmpty) return;
    final trimmed = reason.trim();
    await _service.escalate(
      widget.assignment.patientUserId,
      {'urgency': 'URGENT', 'reason': trimmed},
    );
  }

  Future<String?> _promptText(String label,
      {String? hint, bool multiline = false}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: multiline ? 4 : 1,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('OK')),
        ],
      ),
    );
    return result;
  }
}