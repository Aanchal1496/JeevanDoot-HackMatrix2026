import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A medicine reminder configured by the patient on the prescription screen.
class MedicineReminder {
  const MedicineReminder({required this.enabled, required this.time});

  final bool enabled;
  final String time; // "HH:MM"

  Map<String, dynamic> toJson() => {'enabled': enabled, 'time': time};

  static MedicineReminder fromJson(Map<String, dynamic> json) => MedicineReminder(
        enabled: json['enabled'] as bool? ?? false,
        time: json['time'] as String? ?? '08:00',
      );
}

/// Local, device-only state for the icon-based prescription screen.
///
/// The backend does not store per-dose "taken" state or per-medicine reminder
/// preferences, so these live on the device (like the app's local accounts).
class PrescriptionLocalStore {
  PrescriptionLocalStore._();

  static const String _kTakenKey = 'rx_taken_state';
  static const String _kReminderKey = 'rx_medicine_reminders';
  static const String _kFollowUpKey = 'rx_follow_up_reminder';

  // -------------------------------------------------------------------------
  // Taken doses: keyed by "date|medicine|period" (e.g. "2026-08-10|Paracetamol|morning")
  // -------------------------------------------------------------------------

  static Future<Set<String>> loadTaken() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTakenKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>> toggleTaken(
      Set<String> current, String dateKey, String medicine, String period) async {
    final key = '$dateKey|$medicine|$period';
    final next = Set<String>.from(current);
    if (!next.add(key)) next.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTakenKey, jsonEncode(next.toList()));
    return next;
  }

  // -------------------------------------------------------------------------
  // Medicine reminders: keyed by "prescriptionId|medicine"
  // -------------------------------------------------------------------------

  static Future<Map<String, MedicineReminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReminderKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map;
      return map.map((k, v) => MapEntry(
            k.toString(),
            MedicineReminder.fromJson((v as Map).cast<String, dynamic>()),
          ));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveReminder(
      Map<String, MedicineReminder> current, String key, MedicineReminder r) async {
    final next = Map<String, MedicineReminder>.from(current);
    if (r.enabled) {
      next[key] = r;
    } else {
      next.remove(key);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kReminderKey, jsonEncode(next.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // -------------------------------------------------------------------------
  // Follow-up reminder
  // -------------------------------------------------------------------------

  static Future<bool> isFollowUpReminderSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kFollowUpKey) ?? false;
  }

  static Future<void> setFollowUpReminder(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFollowUpKey, enabled);
  }
}
