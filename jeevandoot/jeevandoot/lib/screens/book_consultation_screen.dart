import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/api/patient_service.dart';
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
  String _date = 'today';
  String _time = '17:30';

  Doctor? _doctor;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load doctors. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  static const String _doctorImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuArT-hqVoCBioIJOGfbSVFY6f1_XJroH4snPQUuLqWGbReBDAAwOz2oQqtNlzOWCOP74xhvB7XrZbJP_JykgaXK45P49efo5L3SuNBXUUBuoD1QrBD76DWAeFcvna_p_EkXHiTpt3wdokKm8xUo4ket5WdE3fmYhUifKYQ65w2Mp7aCcwTDr3e6JV7-hAugaTIwiwerQiL8-vGw-UPygrAAT7HI1iNYcUTcK4sKrgrxDZsB1G_RheSm';

  static const List<({String id, String label, int day, String month})> _dates = [
    (id: 'today', label: 'Today', day: 10, month: 'Aug'),
    (id: 'tomorrow', label: 'Tom', day: 11, month: 'Aug'),
    (id: 'mon', label: 'Mon', day: 12, month: 'Aug'),
    (id: 'tue', label: 'Tue', day: 13, month: 'Aug'),
  ];

  static const List<({String id, String label})> _slots = [
    (id: '17:00', label: '5:00 PM'),
    (id: '17:30', label: '5:30 PM'),
    (id: '18:00', label: '6:00 PM'),
    (id: '18:30', label: '6:30 PM'),
  ];

  DateTime _scheduledSlot() {
    const offsets = {'today': 0, 'tomorrow': 1, 'mon': 2, 'tue': 3};
    final dayOffset = offsets[_date] ?? 0;
    final parts = _time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 12 : 12;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    var dt = DateTime.now().add(Duration(days: dayOffset));
    dt = DateTime(dt.year, dt.month, dt.day, hour, minute);
    if (!dt.isAfter(DateTime.now())) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  Future<void> _confirm() async {
    final doctor = _doctor;
    if (doctor == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _patientService.bookAppointment(
        doctorId: doctor.id,
        scheduledAt: _scheduledSlot().toIso8601String(),
        type: _consultType == 'audio' ? 'Audio Consultation' : 'Video Consultation',
      );
      if (!mounted) return;
      final t = _scheduledSlot();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentConfirmationScreen(
            type: _consultType,
            time:
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
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

  static String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Book a Consultation',
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
                label: _submitting ? 'Booking…' : 'Confirm Appointment',
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
                      'Need help booking?',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('An ASHA Worker will contact you.')),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                        textStyle: AppTextStyles.labelLg,
                      ),
                      child: const Text('Ask an ASHA Worker'),
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
              child: Image.network(
                doctor.imageUrl ?? _doctorImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHigh, child: const Icon(Icons.person)),
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
          'Consultation Type',
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
              Expanded(child: _typeOption(scheme, 'video', Icons.videocam, 'Video')),
              Expanded(child: _typeOption(scheme, 'audio', Icons.headphones, 'Audio')),
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
              'Select Date',
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
      onTap: () => setState(() => _date = date.id),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Slots',
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
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
          itemBuilder: (context, index) => _slotChip(scheme, _slots[index]),
        ),
      ],
    );
  }

  Widget _slotChip(ColorScheme scheme, ({String id, String label}) slot) {
    final selected = _time == slot.id;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _time = slot.id),
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
            slot.label,
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
