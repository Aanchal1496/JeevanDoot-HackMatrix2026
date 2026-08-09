/// Result of the backend's /api/symptom-check analysis.
class SymptomResult {
  const SymptomResult({
    required this.success,
    required this.riskScore,
    required this.riskLevel,
    required this.summary,
    required this.symptoms,
    required this.duration,
    required this.severity,
    required this.explanation,
    required this.precautions,
    required this.seekMedicalAttention,
    required this.emergency,
    required this.warningSigns,
    required this.redFlags,
    required this.disclaimer,
  });

  final bool success;
  final int riskScore;
  final String riskLevel; // LOW | MEDIUM | HIGH
  final String summary;
  final List<String> symptoms;
  final String duration;
  final String severity;
  final String explanation;
  final List<String> precautions;
  final bool seekMedicalAttention;
  final bool emergency;
  final List<String> warningSigns;
  final List<String> redFlags;
  final String disclaimer;

  factory SymptomResult.fromJson(Map<String, dynamic> json) => SymptomResult(
        success: json['success'] as bool? ?? true,
        riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'LOW',
        summary: json['summary'] as String? ?? '',
        symptoms:
            (json['symptoms'] as List?)?.cast<String>() ?? const [],
        duration: json['duration'] as String? ?? '',
        severity: json['severity'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        precautions:
            (json['precautions'] as List?)?.cast<String>() ?? const [],
        seekMedicalAttention: json['seek_medical_attention'] as bool? ?? false,
        emergency: json['emergency'] as bool? ?? false,
        warningSigns:
            (json['warning_signs'] as List?)?.cast<String>() ?? const [],
        redFlags: (json['red_flags'] as List?)?.cast<String>() ?? const [],
        disclaimer: json['disclaimer'] as String? ?? '',
      );
}
