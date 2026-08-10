import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  final DoctorService _service = DoctorService(ApiClient.instance);

  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<AvailabilityWindow> _windows = const [];

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
      final windows = await _service.myAvailability();
      if (mounted) {
        setState(() {
          _windows = windows;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? '${AppStrings.tr('Could not load availability.')} (${e.statusCode})'
              : AppStrings.tr('Could not load availability.');
          _loading = false;
        });
      }
    }
  }

  String _dateKey() =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) setState(() => _end = picked);
  }

  Future<void> _save() async {
    String two(int n) => n.toString().padLeft(2, '0');
    final start = '${two(_start.hour)}:${two(_start.minute)}';
    final end = '${two(_end.hour)}:${two(_end.minute)}';
    setState(() => _saving = true);
    try {
      await _service.setAvailability(
        date: _dateKey(),
        startTime: start,
        endTime: end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.tr('Availability set')}: $start - $end',
          ),
        ),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('Could not set availability.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(title: AppStrings.tr('Set Availability')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackSm,
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.tr('New Availability Window'),
                              style: AppTextStyles.labelLg
                                  .copyWith(color: scheme.primary),
                            ),
                            const SizedBox(height: AppSpacing.gutter),
                            _tapField(
                              scheme,
                              icon: Icons.calendar_today,
                              label: AppStrings.tr('Date'),
                              value: _dateKey(),
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: AppSpacing.gutter),
                            Row(
                              children: [
                                Expanded(
                                  child: _tapField(
                                    scheme,
                                    icon: Icons.schedule,
                                    label: AppStrings.tr('From'),
                                    value: _timeLabel(_start),
                                    onTap: _pickStart,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.gutter),
                                Expanded(
                                  child: _tapField(
                                    scheme,
                                    icon: Icons.schedule,
                                    label: AppStrings.tr('To'),
                                    value: _timeLabel(_end),
                                    onTap: _pickEnd,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.gutter),
                            Text(
                              AppStrings.tr(
                                'Patients can book 1-hour slots within this window.',
                              ),
                              style: AppTextStyles.labelSm.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                            PillButton(
                              label: AppStrings.tr('Save Availability'),
                              onPressed: _saving ? null : _save,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        AppStrings.tr('Your Availability'),
                        style: AppTextStyles.headlineMd,
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      if (_windows.isEmpty)
                        SoftCard(
                          child: Text(
                            AppStrings.tr('No availability windows set yet.'),
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onSurfaceVariant),
                          ),
                        )
                      else
                        for (final w in _windows)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.unit,
                            ),
                            child: SoftCard(
                              padding: const EdgeInsets.all(AppSpacing.gutter),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_filled,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: AppSpacing.unit),
                                  Expanded(
                                    child: Text(
                                      '${w.date}  ·  ${w.startTime} - ${w.endTime}',
                                      style: AppTextStyles.bodyMd,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }

  String _timeLabel(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Widget _tapField(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}