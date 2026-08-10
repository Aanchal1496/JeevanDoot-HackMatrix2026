import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/api/patient_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/appointment_confirmation_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class BookConsultationScreen extends StatefulWidget {
  const BookConsultationScreen({super.key});

  @override
  State<BookConsultationScreen> createState() => _BookConsultationScreenState();
}

class _BookConsultationScreenState extends State<BookConsultationScreen> {
  final PatientService _patientService = PatientService(ApiClient.instance);
  final DoctorService _doctorService = DoctorService(ApiClient.instance);

  String _consultType = 'video';
  String _date = '';
  String _time = '';

  Doctor? _doctor;
  List<Map<String, dynamic>> _slots = const [];
  bool _loading = true;
  bool _slotsLoading = false;
  bool _submitting = false;
  String? _error;
  String? _slotError;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().toString().split(' ').first;
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await _doctorService.list();
      final available = doctors.where((d) => d.available).toList();
      final pick = available.isNotEmpty ? available.first : (doctors.isEmpty ? null : doctors.first);
      if (mounted) {
        setState(() {
          _doctor = pick;
          _loading = false;
        });
        _loadSlots();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppStrings.tr('Could not load doctors. Check your connection.');
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadSlots() async {
    final doctor = _doctor;
    if (doctor == null || _date.isEmpty) return;
    setState(() {
      _slotsLoading = true;
      _slotError = null;
    });
    try {
      final slots = await _patientService.doctorSlots(doctor.id, _date);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _time = slots.isNotEmpty ? ((slots.first['start'] ?? '') as String) : '';
        _slotsLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _slotError = AppStrings.tr('Could not load slots.');
          _slotsLoading = false;
        });
      }
    }
  }

  static String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  List<({String id, String label, int day, String month})> get _dates {
    final result = <({String id, String label, int day, String month})>[];
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final d = now.add(Duration(days: i));
      final id = d.toString().split(' ').first;
      final today = d.year == now.year && d.month == now.month && d.day == now.day;
      final tomorrow =
          d.year == now.add(const Duration(days: 1)).year &&
          d.month == now.add(const Duration(days: 1)).month &&
          d.day == now.add(const Duration(days: 1)).day;
      final label = today
          ? AppStrings.tr('Today')
          : tomorrow
              ? AppStrings.tr('Tom')
              : _shortWeekday(d.weekday);
      result.add((id: id, label: label, day: d.day, month: _monthName(d.month)));
    }
    return result;
  }

  static String _shortWeekday(int w) => const [
        '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
      ][w];

  static String _formatHour(String hh, String mm) {
    var hour = int.tryParse(hh) ?? 12;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:${mm.padLeft(2, '0')} $ampm';
  }

  DateTime _scheduledSlot() {
    final parts = _time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 12 : 12;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final dayPart = _date.split('-');
    final y = int.tryParse(dayPart[0]) ?? DateTime.now().year;
    final mo = int.tryParse(dayPart[1]) ?? DateTime.now().month;
    final d = int.tryParse(dayPart[2]) ?? DateTime.now().day;
    return DateTime(y, mo, d, hour, minute);
  }

  Future<void> _confirm() async {
    final doctor = _doctor;
    if (doctor == null || _submitting || _time.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final scheduled = _scheduledSlot().toIso8601String();
      final type =
          _consultType == 'audio' ? 'Audio Consultation' : 'Video Consultation';
      // Appearance in the patient's schedule/records.
      await _patientService.bookAppointment(
        doctorId: doctor.id,
        scheduledAt: scheduled,
        type: type,
      );
      // Creates the teleconsultation so it lands in the doctor's queue.
      await _patientService.bookConsultation(
        doctorId: doctor.id,
        scheduledAt: scheduled,
        riskLevel: 'HIGH',
        symptoms: const ['Fever', 'Chest pain', 'Fatigue'],
      );
      if (!mounted) return;
      final t = _scheduledSlot();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentConfirmationScreen(
            type: _consultType,
            time: _time,
            date: '${t.day} ${_monthName(t.month)}, ${t.year}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: AppStrings.tr('Book a Consultation'),
        trailingIcon: Icons.more_vert,
        onTrailing: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          0,
          AppSpacing.containerMargin,
          140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _doctorCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _consultTypeSelector(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _dateSelector(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _slotSelector(scheme),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          16,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: scheme.surfaceContainerHighest)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, -8),
              blurRadius: 24,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PillButton(
                label: _submitting ? AppStrings.tr('Booking…') : AppStrings.tr('Confirm Appointment'),
                icon: Icons.check_circle,
                onPressed:
                    _submitting || _doctor == null ? null : () => _confirm(),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppStrings.tr('Need help booking?'),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppStrings.tr('An ASHA Worker will contact you.'))),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                        textStyle: AppTextStyles.labelLg,
                      ),
                      child: Text(AppStrings.tr('Ask an ASHA Worker')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doctorCard(ColorScheme scheme) {
    final doctor = _doctor;
    if (_loading || doctor == null) {
      return SoftCard(
        child: _error != null
            ? Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: scheme.error))
            : const LinearProgressIndicator(),
      );
    }
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 80,
              height: 80,
              child: doctor.imageUrl == null
                  ? ColoredBox(
                      color: scheme.surfaceContainerHigh,
                      child: const Icon(Icons.person),
                    )
                  : Image.network(
                      doctor.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.surfaceContainerHigh,
                        child: const Icon(Icons.person),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
                Row(
                  children: [
                    Icon(Icons.medical_services, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      doctor.specialization,
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: AppSpacing.unit,
                  runSpacing: 4,
                  children: [
                    _badge(scheme, Icons.star, scheme.tertiaryContainer, doctor.rating.toStringAsFixed(1)),
                    _badge(scheme, Icons.work, scheme.primary, '${doctor.experienceYears ?? 0}+ years'),
                    _badge(scheme, Icons.currency_rupee, scheme.secondary, '${doctor.fee}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(ColorScheme scheme, IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodyMd.copyWith(
              color: scheme.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _consultTypeSelector(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr('Consultation Type'),
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(child: _typeOption(scheme, 'video', Icons.videocam, AppStrings.tr('Video'))),
              Expanded(child: _typeOption(scheme, 'audio', Icons.headphones, AppStrings.tr('Audio'))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeOption(ColorScheme scheme, String id, IconData icon, String label) {
    final selected = _consultType == id;
    return InkWell(
      onTap: () => setState(() => _consultType = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppSpacing.touchTargetMin,
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateSelector(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tr('Select Date'),
              style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
            ),
            Icon(Icons.calendar_month, size: 18, color: scheme.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.stackSm),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < _dates.length; i++) ...[
                _dateChip(scheme, _dates[i]),
                if (i < _dates.length - 1) const SizedBox(width: AppSpacing.gutter),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateChip(ColorScheme scheme, ({String id, String label, int day, String month}) date) {
    final selected = _date == date.id;
    return InkWell(
      onTap: () {
        if (_date != date.id) {
          setState(() => _date = date.id);
          _loadSlots();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: selected ? 0.15 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.label.toUpperCase(),
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: AppTextStyles.headlineMd.copyWith(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              date.month,
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotSelector(ColorScheme scheme) {
    if (_slotsLoading) {
      return const Column(
        children: [
          SizedBox(height: AppSpacing.stackMd),
          LinearProgressIndicator(),
        ],
      );
    }
    if (_slotError != null) {
      return SoftCard(
        child: Text(
          _slotError!,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.error),
        ),
      );
    }
    if (_slots.isEmpty) {
      return SoftCard(
        child: Text(
          AppStrings.tr('No free slots for this date. Try another day.'),
          style: AppTextStyles.bodyMd
              .copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_filled, size: 18, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              AppStrings.tr('Available Slots (1 hour each)'),
              style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.tr('Doctor has set free time for this day.'),
          style: AppTextStyles.labelSm
              .copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _slots.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.gutter,
            crossAxisSpacing: AppSpacing.gutter,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (context, index) => _slotChip(
            scheme,
            ((_slots[index]['start'] ?? '') as String),
            ((_slots[index]['end'] ?? '') as String),
          ),
        ),
      ],
    );
  }

  Widget _slotChip(ColorScheme scheme, String start, String end) {
    final selected = _time == start;
    final parts = start.split(':');
    final label = parts.length == 2
        ? _formatHour(parts[0], parts[1])
        : start;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _time = start),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
