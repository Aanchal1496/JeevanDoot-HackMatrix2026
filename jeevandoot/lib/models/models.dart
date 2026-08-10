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

/// A booked consultation appointment.
class Appointment {
  const Appointment({
    required this.doctorName,
    required this.specialty,
    required this.type,
    required this.date,
    required this.time,
  });

  final String doctorName;
  final String specialty;
  final String type;
  final String date;
  final String time;
}

/// Persistent patient context shared across screens.
class AppState {
  AppState._();

  static String selectedLanguage = 'hi';
  static String patientName = 'Ramesh';
  static String phone = '+91 98765 43210';
  static bool medicineReminderTaken = false;
  static final List<Appointment> appointments = [];
}

/// Structured symptom returned by the triage engine.
class DetectedSymptom {
  const DetectedSymptom({
    required this.name,
    this.severity,
    this.redFlag = false,
  });

  final String name;
  final String? severity;
  final bool redFlag;

  factory DetectedSymptom.fromJson(Map<String, dynamic> json) => DetectedSymptom(
        name: json['name'] as String,
        severity: json['severity'] as String?,
        redFlag: json['red_flag'] as bool? ?? false,
      );
}

/// Full result of a symptom check (both input methods share this contract).
class SymptomCheckResult {
  const SymptomCheckResult({
    required this.symptoms,
    required this.riskScore,
    required this.riskLevel,
    required this.explanation,
    required this.redFlags,
    required this.selfCare,
    this.queued = false,
  });

  final List<DetectedSymptom> symptoms;
  final int riskScore;
  final String riskLevel; // "Low" | "Medium" | "High"
  final String explanation;
  final List<String> redFlags;
  final List<String> selfCare;
  final bool queued; // true when the check was enqueued offline for later sync

  bool get isHigh => riskLevel.toUpperCase() == 'HIGH';
  bool get isMedium => riskLevel.toUpperCase() == 'MEDIUM';
  bool get isLow => riskLevel.toUpperCase() == 'LOW';

  factory SymptomCheckResult.fromJson(Map<String, dynamic> json) =>
      SymptomCheckResult(
        symptoms: (json['symptoms'] as List<dynamic>? ?? [])
            .map((e) => DetectedSymptom.fromJson(e as Map<String, dynamic>))
            .toList(),
        riskScore: (json['risk_score'] as num? ?? 0).round(),
        riskLevel: json['risk_level'] as String? ?? 'LOW',
        explanation: json['explanation'] as String? ?? '',
        redFlags: (json['red_flags'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        selfCare: (json['self_care'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
