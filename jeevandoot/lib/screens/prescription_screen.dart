import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/profile_screen.dart';
import 'package:jeevandoot/screens/profile_settings.dart';
import 'package:jeevandoot/screens/reminders_screen.dart';
import 'package:jeevandoot/services/api_client.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/services/prescription_i18n.dart';
import 'package:jeevandoot/services/prescription_store.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/medicine_card.dart';

/// List of the patient's prescriptions (entry from Records / dashboard).
class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Prescription> _prescriptions = const [];
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
      final prescriptions = await fetchPrescriptions();
      if (!mounted) return;
      setState(() {
        _prescriptions = prescriptions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your prescriptions.';
      });
    }
  }

  void _open(Prescription prescription) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrescriptionDetailScreen(prescription: prescription),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'JeevanDoot',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            0,
            AppSpacing.containerMargin,
            AppSpacing.stackLg,
          ),
          children: [
            Text(
              'Your Prescriptions',
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Active and past prescriptions from your doctors.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _statusCard(
                scheme,
                icon: Icons.cloud_off,
                title: 'Could not load prescriptions',
                message: _error!,
                action: 'Retry',
                onAction: _load,
              )
            else if (_prescriptions.isEmpty)
              _statusCard(
                scheme,
                icon: Icons.medication_outlined,
                title: 'No prescriptions yet',
                message: 'Your doctors will share prescriptions here.',
              )
            else
              for (final prescription in _prescriptions)
                _prescriptionCard(scheme, prescription),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    required String message,
    String? action,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            title,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            PillButton(label: action, height: 44, onPressed: onAction),
          ],
        ],
      ),
    );
  }

  Widget _prescriptionCard(ColorScheme scheme, Prescription prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(prescription),
          child: Row(
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
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.doctorName,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prescription.date,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${prescription.medicines.length} medicine${prescription.medicines.length == 1 ? '' : 's'}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'ISSUED',
                            style: AppTextStyles.labelSm.copyWith(
                              color: const Color(0xFF15803D),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon-based, vernacular-friendly prescription experience.
///
/// Visual hierarchy: Medicine -> How many -> When -> With/without food ->
/// For how long. Everything is readable at a glance with large icons and
/// large touch targets; the language selector and voice assistant make it
/// accessible to low-literacy users.
class PrescriptionDetailScreen extends StatefulWidget {
  const PrescriptionDetailScreen({super.key, required this.prescription});

  final Prescription prescription;

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  late RxLanguage _lang;
  FlutterTts? _tts;
  bool _speaking = false;
  bool _paused = false;

  Set<String> _taken = {};
  Map<String, MedicineReminder> _reminders = {};
  bool _followUpSet = false;

  RxStrings get _s => RxStrings.of(_lang);

  @override
  void initState() {
    super.initState();
    _lang = RxLanguage.fromCode(AppState.selectedLanguage);
    _initStore();
    _initTts();
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Local state
  // -------------------------------------------------------------------------

  Future<void> _initStore() async {
    final taken = await PrescriptionLocalStore.loadTaken();
    final reminders = await PrescriptionLocalStore.loadReminders();
    final followUp = await PrescriptionLocalStore.isFollowUpReminderSet();
    if (!mounted) return;
    setState(() {
      _taken = taken;
      _reminders = reminders;
      _followUpSet = followUp;
    });
  }

  String get _dateKey =>
      widget.prescription.dateIso.isNotEmpty ? widget.prescription.dateIso : _todayIso();

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleTaken(PrescriptionItem item, String period) async {
    final next = await PrescriptionLocalStore.toggleTaken(
      _taken,
      _dateKey,
      item.name,
      period,
    );
    if (!mounted) return;
    setState(() => _taken = next);
  }

  Future<void> _handleReminderChanged(
      PrescriptionItem item, MedicineReminder reminder) async {
    final key = '${widget.prescription.id}|${item.name}';
    if (reminder.enabled) {
      // Let the patient pick the reminder time when enabling.
      final initial = _parseTime(reminder.time);
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        helpText: _s.setReminder,
      );
      if (picked == null || !mounted) return;
      final next = MedicineReminder(
        enabled: true,
        time: _formatHhMm(picked.hour, picked.minute),
      );
      await PrescriptionLocalStore.saveReminder(_reminders, key, next);
      if (!mounted) return;
      setState(() => _reminders = {..._reminders, key: next});
    } else {
      await PrescriptionLocalStore.saveReminder(_reminders, key, reminder);
      if (!mounted) return;
      setState(() {
        _reminders = {..._reminders}..remove(key);
      });
    }
  }

  Future<void> _toggleFollowUp() async {
    final next = !_followUpSet;
    await PrescriptionLocalStore.setFollowUpReminder(next);
    if (!mounted) return;
    setState(() => _followUpSet = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? _s.followUpReminderAdded : _s.followUpReminderRemoved),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Voice assistance (Text-to-Speech)
  // -------------------------------------------------------------------------

  Future<void> _initTts() async {
    try {
      final tts = FlutterTts();
      tts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _speaking = false;
          _paused = false;
        });
      });
      tts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _speaking = false;
          _paused = false;
        });
      });
      _tts = tts;
    } catch (_) {
      _tts = null;
    }
  }

  Future<void> _speak() async {
    final tts = _tts;
    if (tts == null) {
      _voiceUnavailable();
      return;
    }
    try {
      await tts.stop();
      await tts.setLanguage(_lang.ttsCode);
      await tts.setSpeechRate(0.48);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
      if (!mounted) return;
      setState(() {
        _speaking = true;
        _paused = false;
      });
      await tts.speak(buildSpokenScript(widget.prescription, _lang));
    } catch (_) {
      if (mounted) {
        setState(() {
          _speaking = false;
          _paused = false;
        });
      }
      _voiceUnavailable();
    }
  }

  Future<void> _pause() async {
    final tts = _tts;
    if (tts == null) return;
    try {
      await tts.pause();
      if (!mounted) return;
      setState(() => _paused = true);
    } catch (_) {
      // Pause is not supported on every platform (e.g. web); stop instead.
      await _stop();
    }
  }

  Future<void> _stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _speaking = false;
      _paused = false;
    });
  }

  void _voiceUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_s.voiceUnavailable)),
    );
  }

  // -------------------------------------------------------------------------
  // Language
  // -------------------------------------------------------------------------

  void _setLang(RxLanguage lang) {
    _stop();
    AppState.selectedLanguage = lang.code;
    setState(() => _lang = lang);
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(
                'Language / भाषा',
                style: AppTextStyles.headlineMd
                    .copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            for (final lang in RxLanguage.values)
              ListTile(
                leading: Icon(
                  lang == _lang
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: lang == _lang
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(
                  lang.label,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: lang == _lang
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _setLang(lang);
                },
              ),
            const SizedBox(height: AppSpacing.unit),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          _header(context, scheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.unit,
                AppSpacing.containerMargin,
                AppSpacing.stackMd,
              ),
              children: [
                _summaryCard(scheme),
                const SizedBox(height: AppSpacing.gutter),
                _voiceCard(scheme),
                const SizedBox(height: AppSpacing.gutter),
                if (widget.prescription.medicines.isEmpty)
                  _emptyMedicines(scheme)
                else
                  for (final item in widget.prescription.medicines) ...[
                    MedicineCard(
                      item: item,
                      s: _s,
                      dateIso: widget.prescription.dateIso,
                      reminder: _reminders['${widget.prescription.id}|${item.name}'],
                      onReminderChanged: (r) => _handleReminderChanged(item, r),
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                  ],
                const SizedBox(height: AppSpacing.unit),
                TodayMedicinesSection(
                  medicines: widget.prescription.medicines,
                  s: _s,
                  dateKey: _dateKey,
                  taken: _taken,
                  onToggleTaken: _toggleTaken,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _followUpCard(scheme),
                const SizedBox(height: AppSpacing.stackMd),
                _safetyNote(scheme),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _RxBottomNav(
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  // -- Header ----------------------------------------------------------------

  Widget _header(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.unit,
        left: AppSpacing.unit,
        right: AppSpacing.unit,
        bottom: AppSpacing.unit,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: scheme.onSurfaceVariant),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _s.myPrescription,
                  style: AppTextStyles.headlineLgMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_s.prescribedBy} ${widget.prescription.doctorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.prescription.date,
                      style: AppTextStyles.labelSm
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _languageChip(context, scheme),
        ],
      ),
    );
  }

  Widget _languageChip(BuildContext context, ColorScheme scheme) {
    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _pickLanguage,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                _lang.shortLabel,
                style: AppTextStyles.labelLg.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  // -- Summary ---------------------------------------------------------------

  Widget _summaryCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UserData.name,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_s.patient} • ${_s.consultationDate}: ${widget.prescription.date}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.stackSm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _s.active,
                      style: AppTextStyles.labelLg.copyWith(
                        color: const Color(0xFF0E9F70),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
            child: Divider(height: 1, color: scheme.surfaceContainerHighest),
          ),
          Row(
            children: [
              _summaryItem(
                scheme,
                icon: Icons.medication_outlined,
                label: _s.doctor,
                value: widget.prescription.doctorName,
              ),
              const SizedBox(width: AppSpacing.gutter),
              _summaryItem(
                scheme,
                icon: Icons.event,
                label: _s.consultationDate,
                value: widget.prescription.date,
              ),
            ],
          ),
          if (widget.prescription.followUpDate.isNotEmpty ||
              widget.prescription.followUpTime.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            _summaryItem(
              scheme,
              icon: Icons.event_available,
              label: _s.nextFollowUp,
              value: '${_formatFollowUpDate(widget.prescription.followUpDate)}'
                  '${widget.prescription.followUpTime.isNotEmpty ? ' • ${widget.prescription.followUpTime}' : ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
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
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Voice ----------------------------------------------------------------

  Widget _voiceCard(ColorScheme scheme) {
    final active = _speaking;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.primaryContainer.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔊 ${_s.listen}',
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      active
                          ? (_paused ? _s.pause : _s.speaking)
                          : _s.myPrescription,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Play / Pause / Replay controls
              if (active) ...[
                _voiceControl(
                  scheme,
                  icon: _paused ? Icons.play_arrow : Icons.pause,
                  label: _paused ? _s.play : _s.pause,
                  onTap: _paused ? _speak : _pause,
                ),
                const SizedBox(width: AppSpacing.unit),
                _voiceControl(
                  scheme,
                  icon: Icons.replay,
                  label: _s.replay,
                  onTap: _speak,
                ),
              ] else
                PillButton(
                  label: _s.listen,
                  icon: Icons.play_arrow,
                  height: 48,
                  expanded: false,
                  onPressed: _speak,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voiceControl(
    ColorScheme scheme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: scheme.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Follow-up & safety -----------------------------------------------------

  Widget _emptyMedicines(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.medication_outlined, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.unit),
          Text(
            _s.noPrescriptions,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _followUpCard(ColorScheme scheme) {
    final hasFollowUp =
        widget.prescription.followUpDate.isNotEmpty ||
            widget.prescription.followUpTime.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              color: scheme.tertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 ${_s.nextFollowUp}',
                  style: AppTextStyles.headlineMd
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  hasFollowUp
                      ? '${_formatFollowUpDate(widget.prescription.followUpDate)}'
                          '${widget.prescription.followUpTime.isNotEmpty ? ' • ${widget.prescription.followUpTime}' : ''}'
                      : _s.noPrescriptionsHint,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.unit),
          _followUpButton(scheme),
        ],
      ),
    );
  }

  Widget _followUpButton(ColorScheme scheme) {
    if (_followUpSet) {
      return Material(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: _toggleFollowUp,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackSm,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  _s.reminderOn,
                  style: AppTextStyles.labelLg.copyWith(
                    color: const Color(0xFF0E9F70),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.close,
                  size: 16,
                  color: const Color(0xFF0E9F70).withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return PillButton(
      label: _s.addReminder,
      icon: Icons.alarm_add,
      height: 44,
      expanded: false,
      onPressed: _toggleFollowUp,
    );
  }

  Widget _safetyNote(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety, size: 20, color: scheme.secondary),
          const SizedBox(width: AppSpacing.unit),
          Expanded(
            child: Text(
              _s.safetyNote,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Navigation ------------------------------------------------------------

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 1: // Prescriptions (already here)
        return;
      case 2: // Reminders
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RemindersScreen()),
        );
        return;
      case 3: // Profile
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileTab()),
        );
        return;
    }
  }
}

/// Contextual bottom navigation shown on the prescription screen.
/// Prescriptions is the active tab.
class _RxBottomNav extends StatelessWidget {
  const _RxBottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (
        Icons.description_outlined,
        Icons.description,
        'Prescriptions',
      ),
      (
        Icons.notifications_outlined,
        Icons.notifications,
        'Reminders',
      ),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(child: _item(context, scheme, items[i], i)),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    ColorScheme scheme,
    (IconData, IconData, String) item,
    int index,
  ) {
    final selected = index == 1; // Prescriptions is the active tab
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.$2 : item.$1,
              size: 24,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              item.$3,
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

String _formatHhMm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

TimeOfDay _parseTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

String _formatFollowUpDate(String iso) {
  if (iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
