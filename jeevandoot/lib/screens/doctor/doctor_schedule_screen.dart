import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  final DoctorService _service = DoctorService(ApiClient.instance);

  int? _doctorId;
  List<PatientBrief> _patients = const [];
  int? _selectedPatientId;
  String _type = 'Video Consultation';

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _loading = true;
  bool _submitting = false;
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
      final results = await Future.wait([_service.me(), _service.patients()]);
      final me = results[0] as Map<String, dynamic>;
      final patients = (results[1] as List)
          .map((e) => PatientBrief.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _doctorId = me['id'] as int?;
          _patients = patients;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? '${AppStrings.tr('Could not load patients.')} (${e.statusCode})'
              : AppStrings.tr('Could not load patients.');
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_doctorId == null || _selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('Please select a patient.'))),
      );
      return;
    }
    final scheduled = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    setState(() => _submitting = true);
    try {
      await _service.scheduleAppointment(
        doctorId: _doctorId!,
        patientUserId: _selectedPatientId!,
        scheduledAt: scheduled.toIso8601String(),
        type: _type,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('Could not schedule appointment.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(title: AppStrings.tr('Schedule Appointment')),
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
                      _patientPicker(scheme),
                      const SizedBox(height: AppSpacing.stackMd),
                      _typePicker(scheme),
                      const SizedBox(height: AppSpacing.stackMd),
                      _dateTimeCard(scheme),
                      const SizedBox(height: AppSpacing.stackLg),
                      PillButton(
                        label: AppStrings.tr('Book Appointment'),
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _patientPicker(ColorScheme scheme) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tr('Patient'),
            style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.unit),
          if (_patients.isEmpty)
            Text(
              AppStrings.tr('No patients available.'),
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _selectedPatientId,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: AppStrings.tr('Select a patient'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                for (final p in _patients)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _selectedPatientId = v),
            ),
        ],
      ),
    );
  }

  Widget _typePicker(ColorScheme scheme) {
    final types = [
      ('Video Consultation', Icons.videocam, 'Video'),
      ('Audio Consultation', Icons.call, 'Audio'),
    ];
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tr('Consultation Type'),
            style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              for (final t in types)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = t.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: t == types.last ? 0 : AppSpacing.unit,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.gutter),
                      decoration: BoxDecoration(
                        color: _type == t.$1
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == t.$1
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            t.$2,
                            color: _type == t.$1
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.tr(t.$3),
                            style: AppTextStyles.labelLg.copyWith(
                              color: _type == t.$1
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
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

  Widget _dateTimeCard(ColorScheme scheme) {
    String h(int n) => n.toString().padLeft(2, '0');
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tr('Select Date & Time'),
            style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: _field(
                  scheme,
                  icon: Icons.calendar_today,
                  label: '${_date.day.toString().padLeft(2, '0')}-${_fmtMonth(_date.month)}-${_date.year}',
                  value: AppStrings.tr('Date'),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _field(
                  scheme,
                  icon: Icons.schedule,
                  label: '${h(_time.hour)}:${h(_time.minute)}',
                  value: AppStrings.tr('Time'),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
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
                  value,
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtMonth(int m) => m.toString().padLeft(2, '0');
}