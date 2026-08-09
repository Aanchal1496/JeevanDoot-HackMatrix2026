import 'package:flutter/material.dart';

import 'doctor_models.dart';

/// One interpreted vital from the backend (thresholds live server-side).
class VitalItem {
  const VitalItem({
    required this.type,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusLabel,
  });

  final String type;
  final String label;
  final String value;
  final String unit;
  final String status;
  final String statusLabel;

  bool get isAbnormal => status != 'normal';

  Color colorFor(ColorScheme scheme) {
    if (status == 'normal') return scheme.onSurface;
    if (status.contains('critical')) return scheme.error;
    if (status == 'elevated' || status == 'low') return const Color(0xFFB45309);
    return scheme.onSurface;
  }

  IconData get statusIcon => status.contains('critical')
      ? Icons.warning_amber_rounded
      : Icons.info_outline;

  factory VitalItem.fromJson(Map<String, dynamic> json) => VitalItem(
        type: json['type'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        status: json['status'] as String? ?? 'normal',
        statusLabel: json['status_label'] as String? ?? 'Normal',
      );
}

/// Patient header block of the case file.
class CaseFilePatient {
  const CaseFilePatient({
    required this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.queueStatus,
    required this.waitMinutes,
    required this.waitTime,
  });

  final String id;
  final String patientId;
  final String name;
  final String age;
  final String gender;
  final String bloodGroup;
  final QueueStatus queueStatus;
  final int waitMinutes;
  final String waitTime;

  factory CaseFilePatient.fromJson(Map<String, dynamic> json) =>
      CaseFilePatient(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        name: json['name'] as String? ?? 'Patient',
        age: (json['age'] ?? '').toString(),
        gender: json['gender'] as String? ?? '',
        bloodGroup: json['blood_group'] as String? ?? '',
        queueStatus: QueueStatus.fromApi(json['queue_status'] as String?),
        waitMinutes: (json['wait_minutes'] as num?)?.toInt() ?? 0,
        waitTime: json['wait_time'] as String? ?? '',
      );
}

/// Structured symptom entry (§6 of the case file spec).
class StructuredSymptom {
  const StructuredSymptom({
    required this.name,
    required this.severity,
    required this.duration,
    required this.onset,
    required this.progression,
  });

  final String name;
  final String severity;
  final String duration;
  final String onset;
  final String progression;

  factory StructuredSymptom.fromJson(Map<String, dynamic> json) =>
      StructuredSymptom(
        name: json['name'] as String? ?? '',
        severity: json['severity'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        onset: json['onset'] as String? ?? '',
        progression: json['progression'] as String? ?? '',
      );
}

/// The AI symptom summary section.
class CaseFileSymptomSummary {
  const CaseFileSymptomSummary({
    required this.aiSummary,
    required this.originalAiSummary,
    required this.doctorEditedSummary,
    required this.editedBy,
    required this.editedAt,
    required this.primaryComplaint,
    required this.structuredSymptoms,
    required this.associatedSymptoms,
    required this.duration,
    required this.severity,
    required this.onset,
    required this.progression,
    required this.triggers,
    required this.aggravatingFactors,
    required this.relievingFactors,
  });

  final String aiSummary;
  final String originalAiSummary;
  final String? doctorEditedSummary;
  final String? editedBy;
  final String? editedAt;
  final String? primaryComplaint;
  final List<StructuredSymptom> structuredSymptoms;
  final List<String> associatedSymptoms;
  final String duration;
  final String severity;
  final String onset;
  final String progression;
  final String triggers;
  final String aggravatingFactors;
  final String relievingFactors;

  bool get isDoctorEdited => doctorEditedSummary != null && editedBy != null;

  factory CaseFileSymptomSummary.fromJson(Map<String, dynamic> json) =>
      CaseFileSymptomSummary(
        aiSummary: json['ai_summary'] as String? ?? '',
        originalAiSummary: json['original_ai_summary'] as String? ?? '',
        doctorEditedSummary: json['doctor_edited_summary'] as String?,
        editedBy: json['edited_by'] as String?,
        editedAt: json['edited_at'] as String?,
        primaryComplaint: json['primary_complaint'] as String?,
        structuredSymptoms: (json['structured_symptoms'] as List? ?? const [])
            .map((e) => StructuredSymptom.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
        associatedSymptoms:
            (json['associated_symptoms'] as List?)?.cast<String>() ??
                const [],
        duration: json['duration'] as String? ?? '',
        severity: json['severity'] as String? ?? '',
        onset: json['onset'] as String? ?? '',
        progression: json['progression'] as String? ?? '',
        triggers: json['triggers'] as String? ?? '',
        aggravatingFactors: json['aggravating_factors'] as String? ?? '',
        relievingFactors: json['relieving_factors'] as String? ?? '',
      );
}

/// Patient history section (empty lists = "Not available" on the UI).
class CaseFileHistory {
  const CaseFileHistory({
    required this.conditions,
    required this.medications,
    required this.allergies,
    required this.familyHistory,
    required this.previousConsultations,
    required this.previousHospitalizations,
    required this.previousSurgeries,
  });

  final List<String> conditions;
  final List<String> medications;
  final List<String> allergies;
  final List<String> familyHistory;
  final List<String> previousConsultations;
  final List<String> previousHospitalizations;
  final List<String> previousSurgeries;

  factory CaseFileHistory.fromJson(Map<String, dynamic> json) =>
      CaseFileHistory(
        conditions: (json['conditions'] as List?)?.cast<String>() ?? const [],
        medications: (json['medications'] as List?)?.cast<String>() ?? const [],
        allergies: (json['allergies'] as List?)?.cast<String>() ?? const [],
        familyHistory:
            (json['family_history'] as List?)?.cast<String>() ?? const [],
        previousConsultations:
            (json['previous_consultations'] as List?)?.cast<String>() ??
                const [],
        previousHospitalizations:
            (json['previous_hospitalizations'] as List?)?.cast<String>() ??
                const [],
        previousSurgeries:
            (json['previous_surgeries'] as List?)?.cast<String>() ??
                const [],
      );
}

/// Vitals block including the recording timestamp.
class CaseFileVitals {
  const CaseFileVitals({
    required this.items,
    required this.recordedAt,
    required this.recordedLabel,
  });

  final List<VitalItem> items;
  final String? recordedAt;
  final String recordedLabel;

  factory CaseFileVitals.fromJson(Map<String, dynamic> json) =>
      CaseFileVitals(
        items: (json['items'] as List? ?? const [])
            .map((e) => VitalItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        recordedAt: json['recorded_at'] as String?,
        recordedLabel: json['recorded_label'] as String? ?? '',
      );
}

/// AI risk / triage section — consumed from the existing risk engine.
class CaseFileRiskAssessment {
  const CaseFileRiskAssessment({
    required this.aiRiskScore,
    required this.aiTriageLevel,
    required this.finalTriageLevel,
    required this.triageSource,
    required this.triageReason,
    required this.safetyEscalated,
  });

  final int aiRiskScore;
  final TriageBand aiTriageLevel;
  final TriageBand finalTriageLevel;
  final TriageSource triageSource;
  final String? triageReason;
  final bool safetyEscalated;

  factory CaseFileRiskAssessment.fromJson(Map<String, dynamic> json) =>
      CaseFileRiskAssessment(
        aiRiskScore: (json['ai_risk_score'] as num?)?.toInt() ?? 0,
        aiTriageLevel:
            TriageBand.fromApi(json['ai_triage_level'] as String?),
        finalTriageLevel:
            TriageBand.fromApi(json['final_triage_level'] as String?),
        triageSource: TriageSource.fromApi(json['triage_source'] as String?),
        triageReason: json['triage_reason'] as String?,
        safetyEscalated: json['safety_escalated'] == true ||
            json['safety_escalated'] == 1,
      );
}

/// An important clinical flag — an observation, never a diagnosis.
class CaseFileFlag {
  const CaseFileFlag({
    required this.text,
    required this.category,
    required this.severity,
  });

  final String text;
  final String category;
  final String severity;

  Color colorFor(ColorScheme scheme) {
    if (severity == 'high') return scheme.error;
    return const Color(0xFFB45309);
  }

  factory CaseFileFlag.fromJson(Map<String, dynamic> json) => CaseFileFlag(
        text: json['text'] as String? ?? '',
        category: json['category'] as String? ?? '',
        severity: json['severity'] as String? ?? 'medium',
      );
}

/// AI pre-consultation insights (suggestions for review, not a diagnosis).
class CaseFileInsights {
  const CaseFileInsights({
    required this.keyConcerns,
    required this.informationToClarify,
    required this.suggestedReview,
  });

  final List<String> keyConcerns;
  final List<String> informationToClarify;
  final List<String> suggestedReview;

  factory CaseFileInsights.fromJson(Map<String, dynamic> json) =>
      CaseFileInsights(
        keyConcerns:
            (json['key_concerns'] as List?)?.cast<String>() ?? const [],
        informationToClarify:
            (json['information_to_clarify'] as List?)?.cast<String>() ??
                const [],
        suggestedReview:
            (json['suggested_review'] as List?)?.cast<String>() ?? const [],
      );
}

/// Case file timestamps.
class CaseFileTimestamps {
  const CaseFileTimestamps({
    required this.generatedAt,
    required this.generatedLabel,
    required this.updatedAt,
    required this.updatedLabel,
  });

  final String? generatedAt;
  final String generatedLabel;
  final String? updatedAt;
  final String updatedLabel;

  factory CaseFileTimestamps.fromJson(Map<String, dynamic> json) =>
      CaseFileTimestamps(
        generatedAt: json['generated_at'] as String?,
        generatedLabel: json['generated_label'] as String? ?? '',
        updatedAt: json['updated_at'] as String?,
        updatedLabel: json['updated_label'] as String? ?? '',
      );
}

/// The full aggregated pre-consultation case file.
class CaseFile {
  const CaseFile({
    required this.id,
    required this.patient,
    required this.symptomSummary,
    required this.history,
    required this.vitals,
    required this.riskAssessment,
    required this.flags,
    required this.aiInsights,
    required this.timestamps,
  });

  final String? id;
  final CaseFilePatient patient;
  final CaseFileSymptomSummary symptomSummary;
  final CaseFileHistory history;
  final CaseFileVitals vitals;
  final CaseFileRiskAssessment riskAssessment;
  final List<CaseFileFlag> flags;
  final CaseFileInsights aiInsights;
  final CaseFileTimestamps timestamps;

  factory CaseFile.fromJson(Map<String, dynamic> json) => CaseFile(
        id: json['id'] as String?,
        patient: CaseFilePatient.fromJson(
            (json['patient'] as Map? ?? const {}).cast<String, dynamic>()),
        symptomSummary: CaseFileSymptomSummary.fromJson(
            (json['symptom_summary'] as Map? ?? const {})
                .cast<String, dynamic>()),
        history: CaseFileHistory.fromJson(
            (json['history'] as Map? ?? const {}).cast<String, dynamic>()),
        vitals: CaseFileVitals.fromJson(
            (json['vitals'] as Map? ?? const {}).cast<String, dynamic>()),
        riskAssessment: CaseFileRiskAssessment.fromJson(
            (json['risk_assessment'] as Map? ?? const {})
                .cast<String, dynamic>()),
        flags: (json['flags'] as List? ?? const [])
            .map((e) => CaseFileFlag.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        aiInsights: CaseFileInsights.fromJson(
            (json['ai_insights'] as Map? ?? const {}).cast<String, dynamic>()),
        timestamps: CaseFileTimestamps.fromJson(
            (json['timestamps'] as Map? ?? const {}).cast<String, dynamic>()),
      );
}
