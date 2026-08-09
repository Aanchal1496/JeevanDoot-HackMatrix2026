import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jeevandoot/models/consultation_models.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/appointment_confirmation_screen.dart';
import 'package:jeevandoot/screens/profile_settings.dart';
import 'package:jeevandoot/services/api_client.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/consultation_widgets.dart';

/// The 5-step teleconsultation booking wizard.
///
/// Steps: 1 Consultation type, 2 Doctor (specialty + doctor),
/// 3 Schedule (date + slot), 4 Details (patient + reason + attachments),
/// 5 Confirm. Going back preserves every selection.
class ConsultationBookingFlowScreen extends StatefulWidget {
  const ConsultationBookingFlowScreen({super.key});

  @override
  State<ConsultationBookingFlowScreen> createState() =>
      _ConsultationBookingFlowScreenState();
}

class _ConsultationBookingFlowScreenState
    extends State<ConsultationBookingFlowScreen> {
  static const List<String> _steps = [
    'Consultation',
    'Doctor',
    'Schedule',
    'Details',
    'Confirm',
  ];

  static const List<String> _allowedAttachmentExt = [
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf',
  ];
  static const int _maxAttachmentBytes = 5 * 1024 * 1024;

  int _step = 0;

  // Step 0 — how would you like to book?
  BookingMode? _mode;
  ConsultKind _consultKind = ConsultKind.video;

  // Step 1 — specialty + doctor
  List<ConsultationSpecialty> _specialties = const [];
  bool _specialtiesLoading = true;
  String? _specialtiesError;
  String _specialtyQuery = '';
  ConsultationSpecialty? _selectedSpecialty;
  List<DoctorInfo> _doctors = const [];
  bool _doctorsLoading = false;
  String? _doctorsError;
  String _doctorQuery = '';
  DoctorInfo? _selectedDoctor;

  // Step 2 — schedule
  List<SlotDateInfo> _dates = const [];
  bool _datesLoading = false;
  String? _datesError;
  SlotDateInfo? _selectedDate;
  DoctorSlots? _slotsResult;
  bool _slotsLoading = false;
  String? _slotsError;
  String? _selectedSlotId;

  // Step 3 — details
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();
  List<ConsultationAttachment> _attachments = [];

  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _prefillPatient();
    _loadSpecialties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _prefillPatient() {
    _nameController.text = UserData.name;
    _ageController.text = UserData.age;
    _genderController.text = UserData.gender;
    _phoneController.text = UserData.phone;
    _locationController.text = UserData.address;
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

  Future<void> _loadSpecialties() async {
    setState(() {
      _specialtiesLoading = true;
      _specialtiesError = null;
    });
    try {
      final list = await fetchConsultationSpecialties();
      if (!mounted) return;
      setState(() {
        _specialties = list;
        _specialtiesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _specialtiesLoading = false;
        _specialtiesError = 'Unable to load consultation details.';
      });
    }
  }

  Future<void> _selectSpecialty(ConsultationSpecialty s) async {
    setState(() {
      _selectedSpecialty = s;
      _selectedDoctor = null;
      _doctors = const [];
      _doctorsLoading = true;
      _doctorsError = null;
      _doctorQuery = '';
    });
    try {
      final list = await fetchConsultationDoctors(specialty: s.id);
      if (!mounted) return;
      setState(() {
        _doctors = list;
        _doctorsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _doctorsLoading = false;
        _doctorsError = 'Unable to load doctors.';
      });
    }
  }

  Future<void> _selectDoctor(DoctorInfo d, {bool goToSchedule = true}) async {
    setState(() {
      _selectedDoctor = d;
      _dates = const [];
      _datesLoading = true;
      _datesError = null;
      _selectedDate = null;
      _slotsResult = null;
      _selectedSlotId = null;
    });
    try {
      final dates = await fetchDoctorDates(d.id);
      if (!mounted) return;
      setState(() {
        _dates = dates;
        _datesLoading = false;
      });
      // Preselect the first available date.
      if (_selectedDate == null) {
        final first = dates.where((x) => x.available).firstOrNull;
        if (first != null) await _selectDate(first);
      }
      if (goToSchedule && mounted) setState(() => _step = 2);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _datesLoading = false;
        _datesError = 'Unable to load available dates.';
      });
      if (goToSchedule) setState(() => _step = 2);
    }
  }

  Future<void> _selectDate(SlotDateInfo d) async {
    setState(() {
      _selectedDate = d;
      _slotsResult = null;
      _slotsLoading = true;
      _slotsError = null;
      _selectedSlotId = null;
    });
    try {
      final slots = await fetchDoctorSlots(_selectedDoctor!.id, d.id);
      if (!mounted) return;
      setState(() {
        _slotsResult = slots;
        _slotsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slotsLoading = false;
        _slotsError = 'Unable to load time slots.';
      });
    }
  }

  Future<void> _pickCalendarDate() async {
    final available = _dates.where((d) => d.available).toList();
    if (available.isEmpty) return;
    final first = DateTime.parse(available.first.id);
    final last = DateTime.parse(available.last.id);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null
          ? DateTime.parse(_selectedDate!.id)
          : first,
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: (day) {
        final key = day.toIso8601String().substring(0, 10);
        return _dates.any((d) => d.id == key && d.available);
      },
      helpText: 'Select consultation date',
      cancelText: 'Close',
      confirmText: 'Select',
    );
    if (picked == null || !mounted) return;
    final key = picked.toIso8601String().substring(0, 10);
    final match = _dates.where((d) => d.id == key).firstOrNull;
    if (match != null) _selectDate(match);
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedAttachmentExt,
      allowMultiple: true,
      withData: false,
    );
    if (result == null || !mounted) return;
    final added = <ConsultationAttachment>[];
    for (final file in result.files) {
      final ext = (file.extension ?? '').toLowerCase();
      if (!_allowedAttachmentExt.contains(ext)) {
        _showMessage('${file.name} has an unsupported file type.');
        continue;
      }
      if (file.size > _maxAttachmentBytes) {
        _showMessage('${file.name} is larger than 5 MB.');
        continue;
      }
      added.add(ConsultationAttachment(name: file.name, size: file.size, type: ext));
    }
    if (added.isNotEmpty) {
      setState(() => _attachments = [..._attachments, ...added]);
      _showMessage('${added.length} file${added.length == 1 ? '' : 's'} attached.', error: false);
    }
  }

  // -------------------------------------------------------------------------
  // Booking
  // -------------------------------------------------------------------------

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _mode == BookingMode.self;
      case 1:
        return _selectedDoctor != null;
      case 2:
        return _selectedSlotId != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  String get _ctaLabel {
    switch (_step) {
      case 0:
        return 'Continue';
      case 1:
        return _selectedDoctor == null ? 'Select a doctor' : 'Continue';
      case 2:
        return _selectedSlotId == null ? 'Select a time slot' : 'Continue';
      case 3:
        return 'Review Booking';
      case 4:
        return _booking ? 'Booking…' : 'Confirm & Book Consultation';
      default:
        return 'Continue';
    }
  }

  void _goNext() {
    if (_step == 0 && _mode == BookingMode.asha) {
      _showAshaComingSoon();
      return;
    }
    if (!_canContinue) return;
    if (_step < 4) {
      setState(() => _step += 1);
    } else {
      _confirmBooking();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmBooking() async {
    if (_booking) return;
    setState(() => _booking = true);
    try {
      final appointment = await bookConsultation(
        doctorId: _selectedDoctor!.id,
        date: _selectedDate!.id,
        startTime: _selectedSlotId!,
        consultKind: _consultKind,
        reason: _reasonController.text.trim(),
        attachments: _attachments,
        bookingSource: 'SELF',
        patientName: _nameController.text.trim(),
        patientPhone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppointmentConfirmationScreen(appointment: appointment),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _booking = false);
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _booking = false);
      _showMessage('Your appointment could not be booked. Please try again.');
    }
  }

  void _showAshaComingSoon() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          0,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent, color: scheme.tertiary, size: 28),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'ASHA-assisted booking',
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'An ASHA worker can help you find a suitable doctor and schedule your teleconsultation. This option is coming in the next update — you can book yourself right now.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            PillButton(
              label: 'Book Myself',
              icon: Icons.person,
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _mode = BookingMode.self);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        onBack: _goBack,
        title: 'Book Teleconsultation',
        trailingIcon: Icons.close,
        // The close affordance only makes sense while inside the flow.
        hideTrailing: _step == 0,
        onTrailing: _goBack,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.stackSm,
              AppSpacing.containerMargin,
              0,
            ),
            child: ConsultationProgressHeader(currentStep: _step, steps: _steps),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.stackMd,
                AppSpacing.containerMargin,
                24,
              ),
              child: switch (_step) {
                0 => _stepType(scheme),
                1 => _stepDoctor(scheme),
                2 => _stepSchedule(scheme),
                3 => _stepDetails(scheme),
                _ => _stepConfirm(scheme),
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(scheme),
    );
  }

  Widget _bottomBar(ColorScheme scheme) {
    return Container(
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
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, -8), blurRadius: 24),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PillButton(
              label: _ctaLabel,
              icon: _step == 4 ? Icons.check_circle : Icons.arrow_forward,
              loading: _booking,
              onPressed: _step == 4 && _booking ? null : _goNext,
            ),
            if (_step == 4)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.unit),
                child: Text(
                  'By booking you agree to consult a qualified doctor. JeevanDoot does not diagnose or prescribe.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Step 0: How would you like to book? -----------------------------------

  Widget _stepType(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How would you like to book?',
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Both options connect you with a qualified doctor for a secure video or audio consultation.',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _modeCard(
          scheme,
          selected: _mode == BookingMode.self,
          icon: Icons.person,
          iconColor: scheme.primary,
          title: 'Self Booking',
          subtitle: 'Book a consultation yourself',
          cta: 'Continue',
          onTap: () => setState(() => _mode = BookingMode.self),
        ),
        const SizedBox(height: AppSpacing.gutter),
        _modeCard(
          scheme,
          selected: _mode == BookingMode.asha,
          icon: Icons.support_agent,
          iconColor: scheme.tertiary,
          title: 'ASHA Assisted',
          subtitle: 'Get help from an ASHA worker to book your consultation',
          cta: 'Request Assistance',
          badge: 'Next update',
          onTap: () => setState(() => _mode = BookingMode.asha),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SectionLabel('Consultation type'),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              for (final kind in ConsultKind.values)
                Expanded(child: _kindOption(scheme, kind)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeCard(
    ColorScheme scheme, {
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String cta,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.14) : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: selected ? 0.14 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: AppTextStyles.labelSm.copyWith(
                                color: scheme.onTertiaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cta,
                      style: AppTextStyles.labelLg.copyWith(
                        color: selected ? scheme.primary : scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindOption(ColorScheme scheme, ConsultKind kind) {
    final selected = _consultKind == kind;
    return InkWell(
      onTap: () => setState(() => _consultKind = kind),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppSpacing.touchTargetMin,
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(kind.icon, color: selected ? scheme.primary : scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(
              kind.label.replaceAll(' Consultation', ''),
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

  // -- Step 1: specialty + doctor --------------------------------------------

  Widget _stepDoctor(ColorScheme scheme) {
    final filtered = _specialties
        .where((s) =>
            _specialtyQuery.isEmpty ||
            s.name.toLowerCase().contains(_specialtyQuery.toLowerCase()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Specialty',
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the specialty that best matches your concern.',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        TextField(
          onChanged: (v) => setState(() => _specialtyQuery = v),
          decoration: const InputDecoration(
            hintText: 'Search specialties',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        if (_specialtiesLoading)
          const ConsultationLoading()
        else if (_specialtiesError != null)
          ConsultationError(title: _specialtiesError!, onRetry: _loadSpecialties)
        else ...[
          Wrap(
            spacing: AppSpacing.gutter,
            runSpacing: AppSpacing.gutter,
            children: [
              for (final s in filtered)
                _specialtyCard(scheme, s),
            ],
          ),
          if (filtered.isEmpty)
            ConsultationEmpty(
              icon: Icons.search_off,
              title: 'No specialties found',
              message: 'Try a different search term.',
            ),
          const SizedBox(height: AppSpacing.stackMd),
          if (_selectedSpecialty != null) ...[
            SectionLabel(
              'Doctors — ${_selectedSpecialty!.name}',
              trailing: Text(
                '${_doctors.length} available',
                style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              onChanged: (v) => setState(() => _doctorQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search doctors',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            if (_doctorsLoading)
              const ConsultationLoading()
            else if (_doctorsError != null)
              ConsultationError(
                title: _doctorsError!,
                onRetry: () => _selectSpecialty(_selectedSpecialty!),
              )
            else if (_doctors.isEmpty)
              ConsultationEmpty(
                icon: Icons.medical_services_outlined,
                title: 'No doctors are available for this specialty.',
                message: 'Please try another specialty.',
              )
            else
              for (final d in _filteredDoctors) ...[
                DoctorCard(
                  doctor: d,
                  selected: _selectedDoctor?.id == d.id,
                  onTap: () => setState(() => _selectedDoctor = d),
                  onViewSlots: () => _selectDoctor(d),
                ),
                const SizedBox(height: AppSpacing.gutter),
              ],
          ],
        ],
      ],
    );
  }

  List<DoctorInfo> get _filteredDoctors {
    final q = _doctorQuery.trim().toLowerCase();
    if (q.isEmpty) return _doctors;
    return _doctors
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.specialization.toLowerCase().contains(q))
        .toList();
  }

  Widget _specialtyCard(ColorScheme scheme, ConsultationSpecialty s) {
    final selected = _selectedSpecialty?.id == s.id;
    return InkWell(
      onTap: () => _selectSpecialty(s),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.of(context).size.width - AppSpacing.containerMargin * 2 - AppSpacing.gutter) / 2,
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.16) : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                s.icon,
                color: selected ? scheme.onPrimary : scheme.primary,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              s.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLg.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${s.doctorCount} doctor${s.doctorCount == 1 ? '' : 's'}',
              style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // -- Step 2: schedule -------------------------------------------------------

  Widget _stepSchedule(ColorScheme scheme) {
    final doctor = _selectedDoctor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Date & Time',
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        if (doctor != null)
          Text(
            '${doctor.name} • ${doctor.specialization}',
            style: AppTextStyles.bodyMd.copyWith(color: scheme.primary),
          ),
        const SizedBox(height: AppSpacing.stackMd),
        SectionLabel(
          'Select Date',
          trailing: TextButton.icon(
            onPressed: _pickCalendarDate,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('Calendar'),
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        if (_datesLoading)
          const SkeletonCard(height: 96)
        else if (_datesError != null)
          ConsultationError(
            title: _datesError!,
            onRetry: () => _selectedDoctor != null
                ? _selectDoctor(_selectedDoctor!, goToSchedule: false)
                : () {},
          )
        else
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _dates.length; i++) ...[
                  DateChip(
                    date: _dates[i],
                    selected: _selectedDate?.id == _dates[i].id,
                    onTap: () => _selectDate(_dates[i]),
                  ),
                  if (i < _dates.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.stackMd),
        if (_selectedDate != null) ...[
          SectionLabel('Time slots — ${_selectedDate!.full}'),
          const SizedBox(height: AppSpacing.stackSm),
          if (_slotsLoading)
            const ConsultationLoading(count: 2)
          else if (_slotsError != null)
            ConsultationError(title: _slotsError!, onRetry: () => _selectDate(_selectedDate!))
          else if (_slotsResult == null || _slotsResult!.slots.isEmpty)
            ConsultationEmpty(
              icon: Icons.event_busy,
              title: 'No available slots for this date.',
              message: 'Choose another date to see more options.',
              ctaLabel: 'Choose another date',
              onCta: () => _pickCalendarDate(),
            )
          else
            _slotGroups(scheme),
        ],
      ],
    );
  }

  Widget _slotGroups(ColorScheme scheme) {
    const periods = {
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'evening': 'Evening',
    };
    final grouped = <String, List<ConsultationSlot>>{};
    for (final s in _slotsResult!.slots) {
      grouped.putIfAbsent(s.period, () => []).add(s);
    }
    final availableCount =
        _slotsResult!.slots.where((s) => s.status == SlotStatus.available).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$availableCount slot${availableCount == 1 ? '' : 's'} available',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        for (final entry in periods.entries)
          if (grouped[entry.key] != null) ...[
            Text(
              entry.value,
              style: AppTextStyles.labelLg.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in grouped[entry.key]!)
                  SlotChip(
                    slot: slot,
                    selected: _selectedSlotId == slot.id,
                    onTap: () => setState(() => _selectedSlotId = slot.id),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ],
      ],
    );
  }

  // -- Step 3: details ---------------------------------------------------------

  Widget _stepDetails(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Patient Details',
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Pre-filled from your profile. Update anything that changed.',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SoftCard(
          child: Column(
            children: [
              _detailField(_nameController, 'Full name', Icons.person_outline),
              const SizedBox(height: AppSpacing.gutter),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _detailField(_ageController, 'Age', Icons.cake_outlined, number: true),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: _detailField(_genderController, 'Gender', Icons.wc),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              _detailField(_phoneController, 'Phone number', Icons.phone_outlined, number: true),
              const SizedBox(height: AppSpacing.gutter),
              _detailField(_locationController, 'Location', Icons.location_on_outlined),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'What would you like to discuss?',
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _reasonController,
          maxLines: 4,
          minLines: 3,
          decoration: const InputDecoration(
            hintText: 'Briefly describe your symptoms or reason for consultation…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SectionLabel('Attachments (optional)'),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Previous prescription, medical report, lab report or a relevant image. Max 5 MB each (JPG, PNG, WebP, HEIC, PDF).',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        if (_attachments.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _attachments.length; i++)
                _attachmentChip(scheme, _attachments[i], i),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
        ],
        OutlinedButton.icon(
          onPressed: _pickAttachments,
          icon: const Icon(Icons.attach_file),
          label: const Text('Attach a file'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: scheme.secondary, size: 20),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: Text(
                  'Your doctor will review your information during the consultation. JeevanDoot does not diagnose or prescribe.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _attachmentChip(ColorScheme scheme, ConsultationAttachment att, int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            att.type == 'pdf' ? Icons.description : Icons.image_outlined,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${att.name} • ${att.sizeLabel}',
            style: AppTextStyles.labelSm.copyWith(color: scheme.onSurface),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _attachments.removeAt(index)),
            tooltip: 'Remove attachment',
          ),
        ],
      ),
    );
  }

  // -- Step 4: summary ---------------------------------------------------------

  Widget _stepConfirm(ColorScheme scheme) {
    final doctor = _selectedDoctor!;
    final date = _selectedDate!;
    final slot = _slotsResult!.slots
        .where((s) => s.id == _selectedSlotId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Consultation Summary',
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Please review the details before confirming.',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DoctorCard(doctor: doctor, compact: true),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.gutter),
                child: Divider(height: 1),
              ),
              _summaryRow(scheme, Icons.medical_services_outlined, 'Specialty', doctor.specialization),
              _summaryRow(scheme, Icons.calendar_today_outlined, 'Date', date.full),
              _summaryRow(scheme, Icons.schedule, 'Time', slot?.label ?? ''),
              _summaryRow(scheme, _consultKind.icon, 'Consultation type', _consultKind.label),
              _summaryRow(scheme, Icons.person_outline, 'Patient', _nameController.text.trim()),
              if (_reasonController.text.trim().isNotEmpty)
                _summaryRow(scheme, Icons.notes, 'Reason', _reasonController.text.trim()),
              _summaryRow(scheme, Icons.currency_rupee, 'Fee', doctor.feeLabel),
              if (_attachments.isNotEmpty)
                _summaryRow(
                  scheme,
                  Icons.attach_file,
                  'Attachments',
                  '${_attachments.length} file${_attachments.length == 1 ? '' : 's'}',
                ),
              if (AppState.lastTriageSummary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackSm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: scheme.tertiary),
                          const SizedBox(width: 8),
                          Text(
                            'AI-generated pre-consultation summary — for clinician review',
                            style: AppTextStyles.labelSm.copyWith(
                              color: scheme.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppState.lastTriageSummary,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: StatusColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StatusColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: StatusColors.success, size: 20),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: Text(
                  'Secure video consultation. You can join from the app 10 minutes before the scheduled time.',
                  style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(ColorScheme scheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.secondary),
          const SizedBox(width: AppSpacing.unit),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
