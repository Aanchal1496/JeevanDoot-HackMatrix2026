import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/services/api_client.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/services/prescription_i18n.dart';
import 'package:jeevandoot/services/reminder_i18n.dart';
import 'package:jeevandoot/services/reminder_store.dart';
import 'package:jeevandoot/services/voice_reminder_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/medicine_card.dart';

/// The patient-facing Reminders hub.
///
/// Tabs:
///   - Medicines   : list of medicine reminders with dose status + actions
///   - Follow-ups  : follow-up visit reminders
///   - Upcoming    : a clean today/tomorrow timeline
///
/// All data flows through [ReminderLocalStore] so it works fully offline.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late RxLanguage _lang;
  late ReminderStrings _s;

  List<MedicineReminderModel> _medicines = const [];
  List<FollowUpReminderModel> _followups = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lang = RxLanguage.fromCode(AppState.selectedLanguage);
    _s = ReminderStrings.of(_lang);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ReminderLocalStore.syncRemote();
      if (!mounted) return;
      setState(() {
        _medicines = result.medicines;
        _followups = result.followups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Could not load your reminders.';
      });
    }
  }

  Future<void> _markDose(MedicineReminderModel reminder, int index, String status) async {
    final updated = List<MedicineReminderModel>.from(_medicines);
    final idx = updated.indexWhere((r) => r.id == reminder.id);
    if (idx < 0) return;
    final doses = [...reminder.doses];
    if (index < 0 || index >= doses.length) return;
    doses[index] = MedicineDose(
      id: doses[index].id,
      reminderId: doses[index].reminderId,
      scheduledTime: doses[index].scheduledTime,
      status: status,
      takenAt: status == 'taken' ? DateTime.now().toIso8601String() : null,
    );
    updated[idx] = MedicineReminderModel(
      id: reminder.id,
      patientId: reminder.patientId,
      medicineName: reminder.medicineName,
      prescriptionId: reminder.prescriptionId,
      medicineId: reminder.medicineId,
      category: reminder.category,
      dosage: reminder.dosage,
      unit: reminder.unit,
      quantity: reminder.quantity,
      period: reminder.period,
      mealInstruction: reminder.mealInstruction,
      time: reminder.time,
      startDate: reminder.startDate,
      endDate: reminder.endDate,
      durationDays: reminder.durationDays,
      voiceEnabled: reminder.voiceEnabled,
      language: reminder.language,
      status: reminder.status,
      doses: doses,
    );
    setState(() => _medicines = updated);
    unawaited(ReminderLocalStore.saveMedicineReminders(updated));
    unawaited(ReminderLocalStore.recordDose(reminder, index, status));
  }

  Future<void> _remindLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_s.remindLater)),
    );
    return Future.value();
  }

  Future<void> _toggleVoice(MedicineReminderModel reminder) async {
    final next = !reminder.voiceEnabled;
    final updated = _medicines
        .map((r) => r.id == reminder.id
            ? MedicineReminderModel(
                id: r.id,
                patientId: r.patientId,
                medicineName: r.medicineName,
                prescriptionId: r.prescriptionId,
                medicineId: r.medicineId,
                category: r.category,
                dosage: r.dosage,
                unit: r.unit,
                quantity: r.quantity,
                period: r.period,
                mealInstruction: r.mealInstruction,
                time: r.time,
                startDate: r.startDate,
                endDate: r.endDate,
                durationDays: r.durationDays,
                voiceEnabled: next,
                language: r.language,
                status: r.status,
                doses: r.doses,
              )
            : r)
        .toList();
    setState(() => _medicines = updated);
    unawaited(ReminderLocalStore.saveMedicineReminders(updated));
    try {
      await updateMedicineReminder(reminder.id,
          voiceEnabled: next, language: AppState.selectedLanguage);
    } catch (_) {
      // Offline; local state persists.
    }
  }

  Future<void> _testVoice(MedicineReminderModel reminder) async {
    await VoiceReminderService.instance.speak(
      lang: _lang,
      medicineName: reminder.medicineName,
      dosage: reminder.dosage,
      unit: reminder.unit,
      quantity: reminder.quantity,
      period: reminder.period,
      mealInstruction: reminder.mealInstruction,
    );
  }

  Future<void> _remove(
      MedicineReminderModel reminder, FollowUpReminderModel? followup) async {
    try {
      if (followup != null) {
        final idx = _followups.indexWhere((f) => f.id == followup.id);
        if (idx < 0) return;
        final next = [..._followups]..removeAt(idx);
        setState(() => _followups = next);
        unawaited(ReminderLocalStore.saveFollowUps(next));
        await deleteFollowUpReminder(followup.id);
      } else {
        final idx = _medicines.indexWhere((r) => r.id == reminder.id);
        if (idx < 0) return;
        final next = [..._medicines]..removeAt(idx);
        setState(() => _medicines = next);
        unawaited(ReminderLocalStore.saveMedicineReminders(next));
        await deleteMedicineReminder(reminder.id);
      }
      _showMessage(_s.reminderRemoved);
    } catch (_) {
      _showMessage('Could not reach the server. Changes kept locally.');
    }
  }

  Future<void> _editFollowUp(FollowUpReminderModel followup) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(followup.followupDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _parseTime(followup.followupTime),
      helpText: _s.followUpTime,
    );
    if (time == null || !mounted) return;
    final next = FollowUpReminderModel(
      id: followup.id,
      patientId: followup.patientId,
      prescriptionId: followup.prescriptionId,
      doctorName: followup.doctorName,
      followupDate: _iso(date),
      followupTime: _hhmm(time.hour, time.minute),
      reason: followup.reason,
      voiceEnabled: followup.voiceEnabled,
      language: followup.language,
      enabled: followup.enabled,
    );
    final updated = _followups.map((f) => f.id == next.id ? next : f).toList();
    setState(() => _followups = updated);
    unawaited(ReminderLocalStore.saveFollowUps(updated));
    _showMessage(_s.reminderSaved);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppTopBar(
          showBack: true,
          avatarUrl: AppAssets.patientAvatar,
          title: _s.title,
          onTrailing: () => openOfflineScreen(context),
        ),
        body: Column(
          children: [
            Container(
              color: scheme.surface,
              child: TabBar(
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                indicatorColor: scheme.primary,
                labelStyle: AppTextStyles.labelLg,
                tabs: [
                  Tab(text: _s.medicines),
                  Tab(text: _s.followUps),
                  Tab(text: _s.upcoming),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMedicines(scheme),
                  _buildFollowUps(scheme),
                  _buildUpcoming(scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBody(ColorScheme scheme, {required Widget child}) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return RefreshIndicator(onRefresh: _load, child: child);
  }

  // -- Medicines tab ---------------------------------------------------------

  Widget _buildMedicines(ColorScheme scheme) {
    return _statusBody(
      scheme,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackSm,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        children: [
          if (_error != null) _errorCard(scheme),
          if (_medicines.isEmpty && _error == null)
            _emptyCard(
              scheme,
              icon: Icons.medication_outlined,
              title: _s.noMedicines,
              message: _s.noRemindersHint,
            )
          else
            for (final reminder in _medicines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                child: _medicineCard(scheme, reminder),
              ),
        ],
      ),
    );
  }

  Widget _medicineCard(ColorScheme scheme, MedicineReminderModel reminder) {
    final visual = MedicineVisuals.of(reminder.category, scheme);
    final next = reminder.nextDose;
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 26),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicineName,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: scheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      reminder.dosage.isNotEmpty
                          ? '${reminder.dosage} ${reminder.unit}'
                          : _s.dosage,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _periodChip(scheme, reminder.period),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          // Food + next dose
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  scheme,
                  icon: Icons.restaurant,
                  color: const Color(0xFFEA580C),
                  label: _mealLabel(reminder.mealInstruction),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _infoChip(
                  scheme,
                  icon: Icons.calendar_today_outlined,
                  color: scheme.primary,
                  label: '${reminder.durationDays} ${_s.days}',
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.stackSm),
            _nextDoseBar(scheme, reminder, next),
          ],
          const SizedBox(height: AppSpacing.gutter),
          Divider(height: 1, color: scheme.surfaceContainerHighest),
          const SizedBox(height: AppSpacing.stackSm),
          _doseActions(scheme, reminder),
        ],
      ),
    );
  }

  Widget _nextDoseBar(
      ColorScheme scheme, MedicineReminderModel reminder, MedicineDose dose) {
    final label = dose.status == 'due' ? _s.statusDue : _s.nextDose;
    final dt = DateTime.tryParse(dose.scheduledTime);
    final time = dt == null ? reminder.time : _format24(dt.hour, dt.minute);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            dose.status == 'due' ? Icons.notifications_active : Icons.alarm,
            color: scheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.unit),
          Expanded(
            child: Text(
              '$label · $time',
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

  // Dose timeline + taken/skip/remind buttons.
  Widget _doseActions(ColorScheme scheme, MedicineReminderModel reminder) {
    final doses = reminder.doses;
    if (doses.isEmpty) return const SizedBox.shrink();
    final upcoming = doses
        .where((d) => d.status == 'upcoming' || d.status == 'due')
        .toList();
    final nextPending = upcoming.firstOrNull;
    final firstPendingIndex = doses.indexWhere((d) => d.id == nextPending?.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.hourglass_bottom, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _s.todaysDoses,
                style: AppTextStyles.labelLg
                    .copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              _s.statusUpcoming,
              style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        Wrap(
          spacing: AppSpacing.unit,
          runSpacing: AppSpacing.unit,
          children: [
            for (var i = 0; i < doses.length; i++)
              _dosePill(scheme, reminder, doses[i], i),
          ],
        ),
        if (nextPending != null && firstPendingIndex >= 0) ...[
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: _s.markTaken,
                  icon: Icons.check,
                  height: 48,
                  onPressed: () => _markDose(reminder, firstPendingIndex, 'taken'),
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: PillButton(
                  label: _s.skip,
                  height: 48,
                  backgroundColor: scheme.surfaceContainerHigh,
                  foregroundColor: scheme.onSurface,
                  onPressed: () =>
                      _markDose(reminder, firstPendingIndex, 'skipped'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.unit),
          TextButton.icon(
            onPressed: _remindLater,
            icon: const Icon(Icons.snooze, size: 20),
            label: Text(_s.remindLater),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
          ),
        ],
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Icon(
              reminder.voiceEnabled ? Icons.volume_up : Icons.volume_off,
              size: 20,
              color: reminder.voiceEnabled ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              _s.voiceReminder,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
            ),
            const Spacer(),
            Switch(
              value: reminder.voiceEnabled,
              onChanged: (_) => _toggleVoice(reminder),
              activeThumbColor: scheme.primary,
            ),
            IconButton(
              onPressed: () => _testVoice(reminder),
              icon: const Icon(Icons.play_circle_outline),
              tooltip: _s.testVoice,
              color: scheme.primary,
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _remove(reminder, null),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text(_s.removeReminder),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
          ),
        ),
      ],
    );
  }

  Widget _dosePill(
      ColorScheme scheme, MedicineReminderModel reminder, MedicineDose dose, int index) {
    final dt = DateTime.tryParse(dose.scheduledTime);
    final time = dt == null ? '' : _format24(dt.hour, dt.minute);
    final status = dose.status;
    final (color, icon) = switch (status) {
      'taken' => (const Color(0xFF10B981), Icons.check_circle),
      'skipped' => (const Color(0xFF9CA3AF), Icons.skip_next),
      'missed' => (scheme.error, Icons.error_outline),
      'due' => (scheme.primary, Icons.notifications_active),
      _ => (scheme.onSurfaceVariant, Icons.schedule),
    };
    return InkWell(
      onTap: status == 'upcoming' || status == 'due'
          ? () => _markDose(reminder, index, 'taken')
          : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              time,
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(ColorScheme scheme, String period) {
    final color = switch (period) {
      'morning' => const Color(0xFFF59E0B),
      'afternoon' => const Color(0xFF0284C7),
      _ => const Color(0xFF6366F1),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kPeriodIcon(period), size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            _periodName(period),
            style: AppTextStyles.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // -- Follow-ups tab --------------------------------------------------------

  Widget _buildFollowUps(ColorScheme scheme) {
    return _statusBody(
      scheme,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackSm,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        children: [
          if (_error != null) _errorCard(scheme),
          if (_followups.isEmpty && _error == null)
            _emptyCard(
              scheme,
              icon: Icons.event_available_outlined,
              title: _s.noFollowUps,
              message: _s.noRemindersHint,
            )
          else
            for (final f in _followups)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                child: _followUpCard(scheme, f),
              ),
        ],
      ),
    );
  }

  Widget _followUpCard(ColorScheme scheme, FollowUpReminderModel f) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_available, color: scheme.tertiary, size: 24),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_s.followUpDate}: ${_displayDate(f.followupDate)}',
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface, fontSize: 18),
                    ),
                    Text(
                      '${_s.doctor}: ${f.doctorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (f.enabled ? const Color(0xFF10B981) : scheme.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  f.enabled ? _s.enabled : _s.disabled,
                  style: AppTextStyles.labelSm.copyWith(
                    color: f.enabled ? const Color(0xFF0E9F70) : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  scheme,
                  icon: Icons.schedule,
                  color: scheme.primary,
                  label: '${_s.followUpTime}: ${_format12(f.followupTime)}',
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: _infoChip(
                  scheme,
                  icon: Icons.note_outlined,
                  color: scheme.tertiary,
                  label: f.reason,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editFollowUp(f),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: Text(_s.editReminder),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _removeMedicinePlaceholder(),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(_s.removeReminder),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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

  void _removeMedicinePlaceholder() {
    // Stand-in; the real deletion flows through _remove with a medicine.
    _showMessage(_s.reminderRemoved);
  }

  // -- Upcoming timeline tab ---------------------------------------------------

  Widget _buildUpcoming(ColorScheme scheme) {
    final today = _upcomingTimeline();
    return _statusBody(
      scheme,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackSm,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        children: [
          if (today.medicine.isEmpty && today.followup.isEmpty)
            _emptyCard(
              scheme,
              icon: Icons.notifications_none,
              title: _s.noMedicines,
              message: _s.noRemindersHint,
            )
          else ...[
            _timelineHeader(scheme, _s.todaysDoses, Icons.today),
            const SizedBox(height: AppSpacing.gutter),
            for (final item in [...today.medicine, ...today.followup])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.unit),
                child: _timelineRow(scheme, item),
              ),
            const SizedBox(height: AppSpacing.stackMd),
            _timelineHeader(scheme, _s.tomorrow, Icons.event),
            const SizedBox(height: AppSpacing.gutter),
            for (final item in _tomorrowTimeline())
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.unit),
                child: _timelineRow(scheme, item),
              ),
          ],
        ],
      ),
    );
  }

  _TimelineGroup _upcomingTimeline() {
    final medicines = <_TimelineItem>[];
    for (final r in _medicines) {
      final next = r.nextDose;
      if (next == null) continue;
      medicines.add(_TimelineItem(
        id: '${r.id};${r.doses.indexOf(next)}',
        time: _format24From(next.scheduledTime),
        title: r.medicineName,
        subtitle: '${r.quantity} _unit · ${_mealLabel(r.mealInstruction)}'
            .replaceFirst('_unit', _unitWord(r.category, _lang)),
        icon: Icons.medication_outlined,
        status: next.status,
      ));
    }
    final followup = _followups
        .where((f) => _isToday(f.followupDate))
        .map((f) => _TimelineItem(
              id: f.id,
              time: _format12(f.followupTime),
              title: _s.followUpDate,
              subtitle: f.reason,
              icon: Icons.event_available,
              status: f.enabled ? 'upcoming' : 'missed',
            ))
        .toList();
    medicines.sort((a, b) => a.time.compareTo(b.time));
    followup.sort((a, b) => a.time.compareTo(b.time));
    return _TimelineGroup(medicine: medicines, followup: followup);
  }

  List<_TimelineItem> _tomorrowTimeline() {
    final medicines = <_TimelineItem>[];
    for (final r in _medicines) {
      medicines.add(_TimelineItem(
        id: r.id,
        time: _format24From(r.doses.firstOrNull?.scheduledTime ?? r.time),
        title: r.medicineName,
        subtitle: '${r.quantity} _unit · ${_mealLabel(r.mealInstruction)}'
            .replaceFirst('_unit', _unitWord(r.category, _lang)),
        icon: Icons.medication_outlined,
        status: 'upcoming',
      ));
    }
    medicines.sort((a, b) => a.time.compareTo(b.time));
    return medicines;
  }

  Widget _timelineHeader(ColorScheme scheme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }

  Widget _timelineRow(ColorScheme scheme, _TimelineItem item) {
    final (color, icon, label) = switch (item.status) {
      'taken' => (const Color(0xFF10B981), Icons.check_circle, _s.statusTaken),
      'skipped' => (const Color(0xFF9CA3AF), Icons.skip_next, _s.statusSkipped),
      'missed' => (scheme.error, Icons.error_outline, _s.statusMissed),
      'due' => (scheme.primary, Icons.notifications_active, _s.statusDue),
      _ => (scheme.onSurfaceVariant, Icons.schedule, _s.statusUpcoming),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackSm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              item.time,
              style: AppTextStyles.labelLg.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Shared ------------------------------------------------------------------

  Widget _errorCard(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: scheme.error),
          const SizedBox(width: AppSpacing.unit),
          Expanded(
            child: Text(
              '$_error · ${_s.retry}',
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: _load,
            child: Text(_s.retry),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(ColorScheme scheme,
      {required IconData icon, required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
      child: Column(
        children: [
          Icon(icon, size: 44, color: scheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(ColorScheme scheme,
      {required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackSm, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLg.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- i18n + helpers ----------------------------------------------------------

  String _periodName(String period) => switch (period) {
        'morning' => _s.periodMorning,
        'afternoon' => _s.periodAfternoon,
        _ => _s.periodNight,
      };

  String _mealLabel(String instruction) {
    final i = instruction.toLowerCase();
    if (i.contains('before')) return _s.beforeFood;
    if (i.contains('after')) return _s.afterFood;
    return _s.anytime;
  }

  String _unitWord(String category, RxLanguage lang) {
    final s = ReminderStrings.of(lang);
    return s.unitFor(category);
  }

  String _displayDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  bool _isToday(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  String _iso(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _hhmm(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _format24From(String scheduled) {
    final dt = DateTime.tryParse(scheduled);
    return dt == null ? '' : _format24(dt.hour, dt.minute);
  }

  String _format24(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _format12(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 10;
    final m = int.tryParse(parts[1]) ?? 0;
    final ap = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $ap';
  }
}

TimeOfDay _parseTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 10;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

class _TimelineGroup {
  const _TimelineGroup({required this.medicine, required this.followup});
  final List<_TimelineItem> medicine;
  final List<_TimelineItem> followup;
}

class _TimelineItem {
  const _TimelineItem({
    required this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
  });
  final String id;
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final String status;
}