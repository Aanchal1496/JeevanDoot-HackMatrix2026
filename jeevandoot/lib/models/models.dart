import 'package:flutter/material.dart';

/// Triage outcome levels produced by the symptom checker flow.
enum TriageLevel { low, consult, urgent }

/// The selectable symptoms in the symptom checker.
class Symptom {
  const Symptom(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

const List<Symptom> kSymptoms = [
  Symptom('fever', 'Fever', Icons.device_thermostat),
  Symptom('cold', 'Cold/Cough', Icons.masks),
  Symptom('headache', 'Headache', Icons.sentiment_very_dissatisfied),
  Symptom('stomach', 'Stomach', Icons.medical_information),
  Symptom('breathing', 'Breathing', Icons.air),
  Symptom('chest', 'Chest', Icons.monitor_heart),
  Symptom('body', 'Body Pain', Icons.accessibility_new),
  Symptom('skin', 'Skin', Icons.face),
];

/// Simple rule-based triage mirroring the demo app outcomes.
TriageLevel computeTriage(Set<String> selectedIds) {
  if (selectedIds.contains('chest') || selectedIds.contains('breathing')) {
    return TriageLevel.urgent;
  }
  if (selectedIds.contains('fever') &&
      (selectedIds.contains('headache') || selectedIds.contains('body'))) {
    return TriageLevel.consult;
  }
  if (selectedIds.length >= 3) {
    return TriageLevel.consult;
  }
  return TriageLevel.low;
}

/// Persistent patient context shared across screens.
class AppState {
  AppState._();

  static String selectedLanguage = 'hi';
  static String patientName = 'Ramesh';
  static String phone = '+91 98765 43210';
  static bool medicineReminderTaken = false;
}
