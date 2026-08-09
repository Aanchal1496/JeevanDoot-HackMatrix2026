import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';

/// Local, device-only reminder state (medicine + follow-up).
///
/// Reminders are stored locally so they keep triggering fully offline. When a
/// connection returns, [syncRemote] pushes local reminders to the backend and
/// pulls any remote ones down. Per-dose status lives here first and is synced
/// to the backend as best-effort.
class ReminderLocalStore {
  ReminderLocalStore._();

  static const String _kMedicineKey = 'local_medicine_reminders';
  static const String _kFollowUpKey = 'local_followup_reminders';
  static const String _kDoseStatusKey = 'local_dose_status';

  // -------------------------------------------------------------------------
  // Medicine reminders
  // -------------------------------------------------------------------------

  static Future<List<MedicineReminderModel>> loadMedicineReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMedicineKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => MedicineReminderModel.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMedicineReminders(
      List<MedicineReminderModel> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kMedicineKey,
        jsonEncode(reminders
            .map((r) => {
                  'id': r.id,
                  'patient_id': r.patientId,
                  'prescription_id': r.prescriptionId,
                  'medicine_id': r.medicineId,
                  'medicine_name': r.medicineName,
                  'category': r.category,
                  'dosage': r.dosage,
                  'unit': r.unit,
                  'quantity': r.quantity,
                  'period': r.period,
                  'meal_instruction': r.mealInstruction,
                  'time': r.time,
                  'start_date': r.startDate,
                  'end_date': r.endDate,
                  'duration_days': r.durationDays,
                  'voice_enabled': r.voiceEnabled,
                  'language': r.language,
                  'status': r.status,
                  'doses': r.doses
                      .map((d) => {
                            'id': d.id,
                            'reminder_id': d.reminderId,
                            'scheduled_time': d.scheduledTime,
                            'status': d.status,
                            'taken_at': d.takenAt,
                          })
                      .toList(),
                })
            .toList()));
  }

  // -------------------------------------------------------------------------
  // Per-dose status overrides (offline-first)
  // -------------------------------------------------------------------------

  static Future<Map<String, String>> loadDoseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDoseStatusKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveDoseStatus(Map<String, String> status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDoseStatusKey, jsonEncode(status));
  }

  /// Records a dose as taken/skipped locally (works offline), then tries to
  /// sync the change to the backend.
  static Future<void> recordDose(
      MedicineReminderModel reminder, int doseIndex, String status) async {
    final statuses = await loadDoseStatus();
    final doses = reminder.doses;
    if (doses.isEmpty || doseIndex < 0 || doseIndex >= doses.length) return;
    statuses[doses[doseIndex].id] = status;
    await saveDoseStatus(statuses);
    try {
      if (status == 'taken') {
        await markDoseTaken(reminder.id);
      } else if (status == 'skipped') {
        await markDoseSkipped(reminder.id);
      }
    } catch (_) {
      // Offline; the local status is retained and will sync later.
    }
  }

  /// Applies any locally recorded dose status onto a list of reminders.
  static Future<List<MedicineReminderModel>> applyLocalDoseStatus(
      List<MedicineReminderModel> reminders) async {
    final statuses = await loadDoseStatus();
    if (statuses.isEmpty) return reminders;
    return reminders.map((r) {
      final doses = r.doses.map((d) {
        final status = statuses[d.id];
        if (status == null || d.status == 'taken' || d.status == 'skipped') {
          return d;
        }
        return MedicineDose(
          id: d.id,
          reminderId: d.reminderId,
          scheduledTime: d.scheduledTime,
          status: status,
          takenAt: status == 'taken' ? d.takenAt : null,
        );
      }).toList();
      return MedicineReminderModel(
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
        voiceEnabled: r.voiceEnabled,
        language: r.language,
        status: r.status,
        doses: doses,
      );
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Follow-up reminders
  // -------------------------------------------------------------------------

  static Future<List<FollowUpReminderModel>> loadFollowUps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFollowUpKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FollowUpReminderModel.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveFollowUps(List<FollowUpReminderModel> followups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kFollowUpKey,
        jsonEncode(followups
            .map((f) => {
                  'id': f.id,
                  'patient_id': f.patientId,
                  'prescription_id': f.prescriptionId,
                  'doctor_name': f.doctorName,
                  'followup_date': f.followupDate,
                  'followup_time': f.followupTime,
                  'reason': f.reason,
                  'voice_enabled': f.voiceEnabled,
                  'language': f.language,
                  'enabled': f.enabled,
                })
            .toList()));
  }

  // -------------------------------------------------------------------------
  // Sync
  // -------------------------------------------------------------------------

  /// Refreshes local reminders from the backend when reachable; otherwise
  /// returns what is stored locally (offline mode).
  static Future<
      ({List<MedicineReminderModel> medicines, List<FollowUpReminderModel> followups})>
      syncRemote() async {
    final localMedicines = await loadMedicineReminders();
    final localFollowUps = await loadFollowUps();
    try {
      final remoteMedicines = await fetchMedicineReminders();
      final remoteFollowUps = await fetchFollowUpReminders();
      final mergedMeds = _mergeMedicine(localMedicines, remoteMedicines);
      final mergedFus = _mergeFollowUp(localFollowUps, remoteFollowUps);
      await saveMedicineReminders(mergedMeds);
      await saveFollowUps(mergedFus);
      return (medicines: mergedMeds, followups: mergedFus);
    } catch (_) {
      return (
        medicines: await applyLocalDoseStatus(localMedicines),
        followups: localFollowUps,
      );
    }
  }

  static List<MedicineReminderModel> _mergeMedicine(
      List<MedicineReminderModel> local, List<MedicineReminderModel> remote) {
    final byId = <String, MedicineReminderModel>{};
    for (final r in remote) {
      byId[r.id] = r;
    }
    for (final r in local) {
      if (!byId.containsKey(r.id)) byId[r.id] = r;
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  static List<FollowUpReminderModel> _mergeFollowUp(
      List<FollowUpReminderModel> local, List<FollowUpReminderModel> remote) {
    final byId = <String, FollowUpReminderModel>{};
    for (final r in remote) {
      byId[r.id] = r;
    }
    for (final r in local) {
      if (!byId.containsKey(r.id)) byId[r.id] = r;
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.followupDate.compareTo(b.followupDate));
    return list;
  }
}