import 'api_client.dart';

/// One saved consultation note (doctor-authored medical record).
class ConsultationNote {
  const ConsultationNote({
    required this.id,
    required this.patientId,
    this.doctorId = '',
    this.doctorName = '',
    this.consultationId = '',
    this.diagnosis = '',
    this.notes = '',
    this.vitals = const {},
    this.symptoms = const [],
    this.aiSummary = '',
    this.createdAt = '',
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String consultationId;
  final String diagnosis;
  final String notes;
  final Map<String, String> vitals;
  final List<String> symptoms;
  final String aiSummary;
  final String createdAt;

  factory ConsultationNote.fromJson(Map<String, dynamic> json) =>
      ConsultationNote(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        doctorId: json['doctor_id'] as String? ?? '',
        doctorName: json['doctor_name'] as String? ?? '',
        consultationId: json['consultation_id'] as String? ?? '',
        diagnosis: json['diagnosis'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        vitals: (json['vitals'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            ) ??
            const {},
        symptoms: (json['symptoms'] as List?)?.cast<String>() ?? const [],
        aiSummary: json['ai_summary'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

/// AI-drafted consultation summary + follow-up suggestion. The AI only drafts;
/// the doctor reviews and edits this text before saving.
class AiSummaryDraft {
  const AiSummaryDraft({
    required this.summary,
    required this.followUp,
    required this.source,
  });

  final String summary;
  final String followUp;
  final String source;
}

/// A scheduled follow-up appointment (from the doctor portal).
class FollowUpAppointment {
  const FollowUpAppointment({
    required this.id,
    required this.patientId,
    this.doctorId = '',
    this.name = '',
    this.date = '',
    this.dateLabel = '',
    this.startTime = '',
    this.time = '',
    this.status = 'Confirmed',
    this.consultType = 'Video Consultation',
    this.reason = '',
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String name;
  final String date;
  final String dateLabel;
  final String startTime;
  final String time;
  final String status;
  final String consultType;
  final String reason;

  factory FollowUpAppointment.fromJson(Map<String, dynamic> json) =>
      FollowUpAppointment(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        doctorId: json['doctor_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        dateLabel: json['date_label'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        time: json['time'] as String? ?? '',
        status: json['status'] as String? ?? 'Confirmed',
        consultType: json['consult_type'] as String? ?? 'Video Consultation',
        reason: json['reason'] as String? ?? '',
      );
}

/// REST calls for the doctor documentation flow: consultation notes, the
/// AI-assisted summary draft, and follow-up scheduling.
class ConsultationNotesService {
  ConsultationNotesService._();

  static final ConsultationNotesService instance = ConsultationNotesService._();

  /// Saves the doctor's consultation note for a patient.
  Future<ConsultationNote> save({
    required String patientId,
    String doctorId = '',
    String doctorName = '',
    String consultationId = '',
    String diagnosis = '',
    String notes = '',
    Map<String, String> vitals = const {},
    List<String> symptoms = const [],
    String aiSummary = '',
  }) async {
    final res = await ApiClient.instance.post(
      '/api/doctor/consultation-notes',
      {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'consultation_id': consultationId,
        'diagnosis': diagnosis,
        'notes': notes,
        'vitals': vitals,
        'symptoms': symptoms,
        'ai_summary': aiSummary,
      },
      timeout: const Duration(seconds: 15),
    ) as Map;
    return ConsultationNote.fromJson(
      (res['note'] as Map).cast<String, dynamic>(),
    );
  }

  /// Returns all saved notes for a patient (newest first).
  Future<List<ConsultationNote>> fetchNotes(String patientId) async {
    final res = await ApiClient.instance
        .get('/api/doctor/consultation-notes/$patientId') as Map;
    return (res['notes'] as List? ?? const [])
        .map((e) => ConsultationNote.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Patient-facing read of their saved consultation notes.
  Future<List<ConsultationNote>> fetchPatientNotes(String patientId) async {
    final res = await ApiClient.instance
        .get('/api/patient/consultation-notes/$patientId') as Map;
    return (res['notes'] as List? ?? const [])
        .map((e) => ConsultationNote.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Asks the backend to draft an AI summary + follow-up suggestion.
  Future<AiSummaryDraft> generateSummary({
    required String patientId,
    String diagnosis = '',
    String notes = '',
  }) async {
    final res = await ApiClient.instance.post(
      '/api/doctor/consultation-notes/ai-summary',
      {'patient_id': patientId, 'diagnosis': diagnosis, 'notes': notes},
      timeout: const Duration(seconds: 30),
    ) as Map;
    return AiSummaryDraft(
      summary: res['summary'] as String? ?? '',
      followUp: res['follow_up'] as String? ?? '',
      source: res['source'] as String? ?? 'template',
    );
  }

  /// Schedules a follow-up appointment for the patient.
  Future<FollowUpAppointment> scheduleFollowUp({
    required String patientId,
    required String doctorId,
    String doctorName = '',
    required String date,
    required String time,
    String reason = '',
    String consultType = 'Video Consultation',
  }) async {
    final res = await ApiClient.instance.post(
      '/api/doctor/follow-ups',
      {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'date': date,
        'time': time,
        'reason': reason,
        'consult_type': consultType,
      },
      timeout: const Duration(seconds: 15),
    ) as Map;
    return FollowUpAppointment.fromJson(
      (res['appointment'] as Map).cast<String, dynamic>(),
    );
  }

  /// Lists follow-ups scheduled by a doctor for a patient.
  Future<List<FollowUpAppointment>> fetchFollowUps(String patientId) async {
    final res = await ApiClient.instance
        .get('/api/doctor/follow-ups/$patientId') as Map;
    return (res['follow_ups'] as List? ?? const [])
        .map((e) => FollowUpAppointment.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Patient-facing read of follow-ups their doctor scheduled.
  Future<List<FollowUpAppointment>> fetchPatientFollowUps(
      String patientId) async {
    final res = await ApiClient.instance
        .get('/api/patient/follow-ups/$patientId') as Map;
    return (res['follow_ups'] as List? ?? const [])
        .map((e) => FollowUpAppointment.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
