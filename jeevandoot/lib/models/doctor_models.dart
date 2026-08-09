import 'package:flutter/material.dart';

enum DoctorRiskLevel { low, medium, high, urgent }

class DoctorRisk {
  const DoctorRisk(this.level, this.label);

  final DoctorRiskLevel level;
  final String label;

  Color get color {
    switch (level) {
      case DoctorRiskLevel.low:
        return const Color(0xFF10B981);
      case DoctorRiskLevel.medium:
        return const Color(0xFFF59E0B);
      case DoctorRiskLevel.high:
      case DoctorRiskLevel.urgent:
        return const Color(0xFFEF4444);
    }
  }
}

/// The three triage bands used by the risk-sorted queue.
///
/// Colors are always paired with an icon, a text label and the risk score so
/// the UI never relies on colour alone (accessibility requirement).
enum TriageBand {
  red('RED', 'HIGH RISK', Icons.fiber_manual_record, Color(0xFFD32F2F)),
  yellow('YELLOW', 'MEDIUM RISK', Icons.fiber_manual_record, Color(0xFFB45309)),
  green('GREEN', 'LOW RISK', Icons.fiber_manual_record, Color(0xFF15803D));

  const TriageBand(this.apiValue, this.label, this.icon, this.color);

  final String apiValue;
  final String label;
  final IconData icon;
  final Color color;

  static TriageBand fromApi(String? value) => values.firstWhere(
        (b) => b.apiValue == (value ?? '').toUpperCase(),
        orElse: () => TriageBand.green,
      );

  DoctorRiskLevel get riskLevel => switch (this) {
        TriageBand.red => DoctorRiskLevel.high,
        TriageBand.yellow => DoctorRiskLevel.medium,
        TriageBand.green => DoctorRiskLevel.low,
      };

  String get riskLabel => switch (this) {
        TriageBand.red => 'High Risk',
        TriageBand.yellow => 'Medium Risk',
        TriageBand.green => 'Low Risk',
      };

  String get description => switch (this) {
        TriageBand.red =>
          'Patient may require urgent medical attention.',
        TriageBand.yellow =>
          'Requires medical attention but is not immediately critical.',
        TriageBand.green =>
          'Currently stable; can wait for routine consultation.',
      };
}

/// Queue lifecycle status of a patient.
enum QueueStatus {
  waiting('WAITING', 'Waiting'),
  inConsultation('IN_CONSULTATION', 'In Consultation'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  const QueueStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static QueueStatus fromApi(String? value) => values.firstWhere(
        (s) => s.apiValue == (value ?? '').toUpperCase(),
        orElse: () => QueueStatus.waiting,
      );
}

/// Who decided the current final triage level.
enum TriageSource {
  ai('AI', 'AI'),
  doctor('DOCTOR', 'Doctor Override'),
  safetyEscalation('SAFETY_ESCALATION', 'Safety Escalation');

  const TriageSource(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TriageSource fromApi(String? value) => values.firstWhere(
        (s) => s.apiValue == (value ?? '').toUpperCase(),
        orElse: () => TriageSource.ai,
      );
}

/// '2 min', '18 min', '1 hr 12 min' - derived from arrival time at render time.
String formatWaitMinutes(int minutes) {
  if (minutes < 1) return '0 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rem = minutes % 60;
  return rem == 0 ? '$hours hr' : '$hours hr $rem min';
}

DateTime? _parseTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

/// A patient in the doctor's queue / case view, carrying the full triage
/// assessment (AI + final) and queue metadata.
class DoctorPatient {
  const DoctorPatient({
    required this.name,
    required this.id,
    required this.age,
    required this.gender,
    this.patientId = '',
    this.bloodGroup = '',
    required this.symptoms,
    this.waitMinutes = 0,
    this.startTime,
    this.consultType = 'Video Consultation',
    this.status = QueueStatus.waiting,
    this.arrivalTime,
    this.aiRiskScore = 0,
    this.aiTriageLevel = TriageBand.green,
    this.aiTriageReason,
    this.finalTriageLevel = TriageBand.green,
    this.triageSource = TriageSource.ai,
    this.triageReason,
    this.doctorOverrideReason,
    this.safetyEscalated = false,
    this.criticalSymptoms = const [],
    this.symptomDuration = '',
    this.symptomSeverity = '',
    this.symptomOnset = '',
    this.vitals = const {},
  });

  final String name;
  final String id;
  final String age;
  final String gender;
  final String patientId;
  final String bloodGroup;
  final List<String> symptoms;
  final int waitMinutes;
  final String? startTime;
  final String consultType;
  final QueueStatus status;
  final DateTime? arrivalTime;
  final int aiRiskScore;
  final TriageBand aiTriageLevel;
  final String? aiTriageReason;
  final TriageBand finalTriageLevel;
  final TriageSource triageSource;
  final String? triageReason;
  final String? doctorOverrideReason;
  final bool safetyEscalated;
  final List<String> criticalSymptoms;
  final String symptomDuration;
  final String symptomSeverity;
  final String symptomOnset;
  final Map<String, String> vitals;

  /// Legacy risk view used by pre-existing doctor screens.
  DoctorRisk get risk =>
      DoctorRisk(finalTriageLevel.riskLevel, finalTriageLevel.riskLabel);

  /// Human waiting time derived from [waitMinutes].
  String get waitTime => formatWaitMinutes(waitMinutes);

  bool get isWaiting => status == QueueStatus.waiting;

  bool get isInConsultation => status == QueueStatus.inConsultation;

  factory DoctorPatient.fromJson(Map<String, dynamic> json) {
    final aiLevelRaw = json['ai_triage_level'] as String?;
    final aiLevel = TriageBand.fromApi(aiLevelRaw);
    final finalLevel =
        TriageBand.fromApi(json['final_triage_level'] as String? ?? aiLevelRaw);
    return DoctorPatient(
      name: json['name'] as String? ?? 'Patient',
      id: json['id'] as String? ?? 'PT-0000',
      patientId: (json['patient_id'] as String?) ??
          (json['id'] as String?) ??
          'PT-0000',
      age: (json['age'] ?? '').toString(),
      gender: json['gender'] as String? ?? 'Male',
      bloodGroup: json['blood_group'] as String? ?? '',
      symptoms: (json['symptoms'] as List?)?.cast<String>() ?? const [],
      waitMinutes: (json['wait_minutes'] as num?)?.toInt() ?? 0,
      startTime: json['start_time'] as String?,
      consultType: json['consult_type'] as String? ?? 'Video Consultation',
      status: QueueStatus.fromApi(json['status'] as String?),
      arrivalTime: _parseTime(json['arrival_time'] as String?),
      aiRiskScore: (json['ai_risk_score'] as num?)?.toInt() ?? 0,
      aiTriageLevel: aiLevel,
      aiTriageReason: json['ai_triage_reason'] as String?,
      finalTriageLevel: finalLevel,
      triageSource: TriageSource.fromApi(json['triage_source'] as String?),
      triageReason: json['triage_reason'] as String?,
      doctorOverrideReason: json['doctor_override_reason'] as String?,
      safetyEscalated: json['safety_escalated'] == true ||
          json['safety_escalated'] == 1,
      criticalSymptoms:
          (json['critical_symptoms'] as List?)?.cast<String>() ?? const [],
      symptomDuration: json['symptom_duration'] as String? ?? '',
      symptomSeverity: json['symptom_severity'] as String? ?? '',
      symptomOnset: json['symptom_onset'] as String? ?? '',
      vitals: (json['vitals'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')) ??
          const {},
    );
  }
}

/// Aggregate counts shown at the top of the queue dashboard.
class QueueSummary {
  const QueueSummary({
    required this.red,
    required this.yellow,
    required this.green,
    required this.totalWaiting,
    required this.inConsultation,
  });

  final int red;
  final int yellow;
  final int green;
  final int totalWaiting;
  final int inConsultation;

  factory QueueSummary.fromJson(Map<String, dynamic> json) => QueueSummary(
        red: (json['red'] as num?)?.toInt() ?? 0,
        yellow: (json['yellow'] as num?)?.toInt() ?? 0,
        green: (json['green'] as num?)?.toInt() ?? 0,
        totalWaiting: (json['total_waiting'] as num?)?.toInt() ?? 0,
        inConsultation: (json['in_consultation'] as num?)?.toInt() ?? 0,
      );
}

class DoctorSummary {
  const DoctorSummary({required this.id, required this.name});

  final String id;
  final String name;

  factory DoctorSummary.fromJson(Map<String, dynamic> json) => DoctorSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

/// The full risk-sorted queue payload from `GET /api/doctor/queue`.
class QueueData {
  const QueueData({
    required this.waiting,
    required this.consulting,
    required this.summary,
    required this.doctors,
  });

  final List<DoctorPatient> waiting;
  final List<DoctorPatient> consulting;
  final QueueSummary summary;
  final List<DoctorSummary> doctors;

  /// Waiting patients first (already risk-sorted by the backend), then
  /// patients in consultation.
  List<DoctorPatient> get all => [...waiting, ...consulting];

  factory QueueData.fromJson(Map<String, dynamic> json) => QueueData(
        waiting: (json['queue'] as List? ?? const [])
            .map((e) => DoctorPatient.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        consulting: (json['consulting'] as List? ?? const [])
            .map((e) => DoctorPatient.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        summary: QueueSummary.fromJson(
          (json['summary'] as Map? ?? const {}).cast<String, dynamic>(),
        ),
        doctors: (json['doctors'] as List? ?? const [])
            .map((e) => DoctorSummary.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// One immutable entry in a patient's triage audit trail.
class TriageHistoryEntry {
  const TriageHistoryEntry({
    required this.id,
    required this.patientId,
    required this.previousLevel,
    required this.newLevel,
    required this.riskScore,
    required this.source,
    required this.reason,
    required this.changedBy,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final TriageBand? previousLevel;
  final TriageBand newLevel;
  final int riskScore;
  final TriageSource source;
  final String reason;
  final String changedBy;
  final DateTime createdAt;

  factory TriageHistoryEntry.fromJson(Map<String, dynamic> json) =>
      TriageHistoryEntry(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        previousLevel: json['previous_level'] == null
            ? null
            : TriageBand.fromApi(json['previous_level'] as String?),
        newLevel: TriageBand.fromApi(json['new_level'] as String?),
        riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
        source: TriageSource.fromApi(json['source'] as String?),
        reason: json['reason'] as String? ?? '',
        changedBy: json['changed_by'] as String? ?? '',
        createdAt: _parseTime(json['created_at'] as String?) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Offline / backend-down fallback demo queue (mirrors the seeded data).
const List<DoctorPatient> kDoctorPatients = [
  DoctorPatient(
    name: 'Rahul Kumar',
    id: 'PT-9942',
    age: '54',
    gender: 'Male',
    patientId: 'PT-9942',
    bloodGroup: 'O+',
    symptoms: ['Chest pain', 'Shortness of breath', 'Fever'],
    waitMinutes: 18,
    aiRiskScore: 87,
    aiTriageLevel: TriageBand.red,
    aiTriageReason:
        'Chest pain and shortness of breath reported; elevated respiratory rate (26 breaths/min).',
    finalTriageLevel: TriageBand.red,
    triageSource: TriageSource.safetyEscalation,
    safetyEscalated: true,
    criticalSymptoms: ['difficulty breathing', 'shortness of breath'],
    symptomDuration: '2 hours',
    symptomSeverity: 'Severe',
    symptomOnset: 'Sudden',
    vitals: {'temp': '38.7', 'hr': '102', 'spo2': '94', 'bp': '138/90', 'rr': '26'},
  ),
  DoctorPatient(
    name: 'Anil Verma',
    id: 'PT-8876',
    age: '51',
    gender: 'Male',
    patientId: 'PT-8876',
    bloodGroup: 'O-',
    symptoms: ['Difficulty breathing', 'Mild cough'],
    waitMinutes: 6,
    aiRiskScore: 61,
    aiTriageLevel: TriageBand.yellow,
    aiTriageReason: 'Difficulty breathing reported.',
    finalTriageLevel: TriageBand.red,
    triageSource: TriageSource.safetyEscalation,
    safetyEscalated: true,
    criticalSymptoms: ['difficulty breathing'],
    symptomDuration: '30 minutes',
    symptomSeverity: 'Moderate',
    symptomOnset: 'Sudden',
    vitals: {'temp': '37.5', 'hr': '96', 'spo2': '93', 'bp': '126/80', 'rr': '22'},
  ),
  DoctorPatient(
    name: 'Priya Sharma',
    id: 'PT-88231',
    age: '45',
    gender: 'Female',
    patientId: 'PT-88231',
    bloodGroup: 'A+',
    symptoms: ['Severe abdominal pain'],
    waitMinutes: 42,
    aiRiskScore: 60,
    aiTriageLevel: TriageBand.yellow,
    aiTriageReason: 'Severe abdominal pain warrants monitoring.',
    finalTriageLevel: TriageBand.red,
    triageSource: TriageSource.safetyEscalation,
    safetyEscalated: true,
    criticalSymptoms: ['severe abdominal pain'],
    symptomDuration: '1 hour',
    symptomSeverity: 'Severe',
    symptomOnset: 'Sudden',
    vitals: {'temp': '37.9', 'hr': '98', 'spo2': '97', 'bp': '128/84', 'rr': '18'},
  ),
  DoctorPatient(
    name: 'Amit Patel',
    id: 'PT-7731',
    age: '45',
    gender: 'Male',
    patientId: 'PT-7731',
    bloodGroup: 'B+',
    symptoms: ['Persistent cough', 'Fatigue'],
    waitMinutes: 25,
    aiRiskScore: 47,
    aiTriageLevel: TriageBand.yellow,
    aiTriageReason: 'Persistent cough with fatigue; moderate severity.',
    finalTriageLevel: TriageBand.yellow,
    triageSource: TriageSource.ai,
    symptomDuration: '1 week',
    symptomSeverity: 'Moderate',
    symptomOnset: 'Gradual',
    vitals: {'temp': '37.2', 'hr': '88', 'spo2': '96', 'bp': '132/88', 'rr': '16'},
  ),
  DoctorPatient(
    name: 'Sunita Rao',
    id: 'PT-8492',
    age: '28',
    gender: 'Female',
    patientId: 'PT-8492',
    bloodGroup: 'O+',
    symptoms: ['Routine checkup', 'Mild rash'],
    waitMinutes: 45,
    aiRiskScore: 12,
    aiTriageLevel: TriageBand.green,
    aiTriageReason: 'Mild symptoms reported; routine consultation advised.',
    finalTriageLevel: TriageBand.green,
    triageSource: TriageSource.ai,
    symptomDuration: '3 days',
    symptomSeverity: 'Mild',
    symptomOnset: 'Gradual',
    vitals: {'temp': '36.8', 'hr': '76', 'spo2': '98', 'bp': '120/80', 'rr': '14'},
  ),
];

/// Appointments for the doctor's schedule screen.
class DoctorAppointment {
  const DoctorAppointment({
    required this.name,
    required this.id,
    required this.time,
    required this.status,
    required this.risk,
    required this.consultType,
    this.startTime,
  });

  final String name;
  final String id;
  final String time;
  final String status;
  final DoctorRisk risk;
  final String consultType;
  final String? startTime;

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    return DoctorAppointment(
      name: json['name'] as String? ?? 'Patient',
      id: json['id'] as String? ?? 'APT-0000',
      time: json['time'] as String? ?? '--:--',
      status: json['status'] as String? ?? 'Upcoming',
      risk: DoctorRisk(
        DoctorRiskLevel.values.firstWhere(
          (l) => l.name == json['risk'],
          orElse: () => DoctorRiskLevel.medium,
        ),
        json['risk_label'] as String? ??
            (json['risk'] as String? ?? 'Medium'),
      ),
      consultType:
          json['consult_type'] as String? ?? 'Video Consultation',
      startTime: json['start_time'] as String?,
    );
  }
}

const List<DoctorAppointment> kDoctorAppointments = [
  DoctorAppointment(
    name: 'Sunita Devi',
    id: 'JD-8492',
    time: '5:30 PM',
    status: 'Upcoming',
    risk: DoctorRisk(DoctorRiskLevel.medium, 'Medium Risk'),
    consultType: 'Video Consultation',
  ),
  DoctorAppointment(
    name: 'Ramesh Kumar',
    id: 'JD-7731',
    time: '4:00 PM',
    status: 'Completed',
    risk: DoctorRisk(DoctorRiskLevel.low, 'Low Risk'),
    consultType: 'In-Person Visit',
  ),
];

/// Medicine entry in the prescription builder.
class MedicineEntry {
  MedicineEntry({
    required this.name,
    required this.category,
    required this.dosage,
    required this.unit,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.days,
    required this.instructions,
  });

  final String name;
  final String category;
  final String dosage;
  final String unit;
  int morning;
  int afternoon;
  int night;
  int days;
  final String instructions;
}

const List<String> kMedicineSearchResults = [
  'Paracetamol',
  'Amoxicillin',
  'Azithromycin',
  'Cetirizine',
  'Metformin',
  'Lisinopril',
  'Ibuprofen',
  'Cough Syrup',
];

/// Persistent doctor context.
class DoctorState {
  DoctorState._();

  static String doctorName = 'Dr. Priya Sharma';
  static String specialization = 'General Physician';
  static String registrationId = 'MCI-78945612';
  static String clinic = 'JeevanDoot Clinic';
  static String workingHours = '9:00 AM – 5:00 PM';
  static String workingDays = 'Monday to Saturday';
  static bool isAvailable = true;
}
