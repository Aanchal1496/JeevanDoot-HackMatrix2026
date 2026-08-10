import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/l10n/app_strings.dart';

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    this.clinic,
    required this.rating,
    this.experienceYears,
    required this.available,
    required this.fee,
    this.imageUrl,
    this.location,
  });
  final int id;
  final String name;
  final String specialization;
  final String? clinic;
  final double rating;
  final int? experienceYears;
  final bool available;
  final int fee;
  final String? imageUrl;
  final String? location;

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Unknown',
        specialization: json['specialization'] as String? ?? '',
        clinic: json['clinic'] as String?,
        rating: (json['rating'] as num? ?? 0).toDouble(),
        experienceYears: json['experience_years'] as int?,
        available: json['available'] as bool? ?? false,
        fee: json['fee'] as int? ?? 0,
        imageUrl: json['image_url'] as String?,
        location: json['location'] as String?,
      );
}

/// A consultation record the doctor is (or was) involved in.
class Consultation {
  const Consultation({
    required this.id,
    required this.patientUserId,
    this.patientName,
    this.type,
    this.status,
    this.scheduledAt,
  });
  final int id;
  final int patientUserId;
  final String? patientName;
  final String? type;
  final String? status;
  final String? scheduledAt;

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation(
        id: json['id'] as int,
        patientUserId: json['user_id'] as int,
        patientName: json['patient_name'] as String? ?? 'Patient',
        type: json['consultation_type'] as String?,
        status: json['status'] as String?,
        scheduledAt: json['scheduled_at']?.toString(),
      );
}

class QueuePatient {
  const QueuePatient({
    required this.triageId,
    required this.patientName,
    required this.symptoms,
    required this.riskLevel,
    this.riskScore,
    this.redFlags,
    this.patientId,
  });
  final int triageId;
  final String patientName;
  final String symptoms;
  final String riskLevel;
  final int? riskScore;
  final String? redFlags;
  final int? patientId;

  factory QueuePatient.fromJson(Map<String, dynamic> json) => QueuePatient(
        triageId: json['triage_id'] as int,
        patientName: json['patient_name'] as String? ?? 'Patient',
        symptoms: json['symptoms'] as String? ?? '',
        riskLevel: (json['risk_level'] as String? ?? 'LOW').toUpperCase(),
        riskScore: json['risk_score'] as int?,
        redFlags: json['red_flags'] as String?,
        patientId: json['patient_id'] as int?,
      );
}

/// A consultation waiting in the doctor's demo queue (risk-sorted).
class ConsultationQueueItem {
  const ConsultationQueueItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.riskLevel,
    required this.status,
    this.age,
    this.gender,
    this.symptoms = const [],
    this.type,
    this.scheduledAt,
  });
  final int id;
  final int patientId;
  final String patientName;
  final String riskLevel;
  final String status;
  final int? age;
  final String? gender;
  final List<String> symptoms;
  final String? type;
  final String? scheduledAt;

  factory ConsultationQueueItem.fromJson(Map<String, dynamic> json) =>
      ConsultationQueueItem(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        patientName: json['patient_name'] as String? ?? 'Patient',
        riskLevel: (json['risk_level'] as String? ?? 'LOW').toUpperCase(),
        status: (json['status'] as String? ?? 'WAITING').toUpperCase(),
        age: json['age'] as int?,
        gender: json['gender'] as String?,
        symptoms: (json['symptoms'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        type: json['consultation_type'] as String?,
        scheduledAt: json['scheduled_at']?.toString(),
      );
}

/// Minimal patient record used by the doctor to pick who to schedule for.
class PatientBrief {
  const PatientBrief({
    required this.id,
    required this.name,
    this.phone,
  });
  final int id;
  final String name;
  final String? phone;

  factory PatientBrief.fromJson(Map<String, dynamic> json) => PatientBrief(
        id: json['id'] as int,
        name: json['name'] as String? ?? AppStrings.tr('Patient'),
        phone: json['phone'] as String?,
      );
}

/// A booked appointment visible on the doctor's Schedule tab.
class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.patientUserId,
    required this.patientName,
    required this.type,
    required this.status,
    this.scheduledAt,
  });
  final int id;
  final int patientUserId;
  final String patientName;
  final String type;
  final String status;
  final String? scheduledAt;

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) =>
      DoctorAppointment(
        id: json['id'] as int,
        patientUserId: json['patient_user_id'] as int,
        patientName: json['patient_name'] as String? ?? AppStrings.tr('Patient'),
        type: json['type'] as String? ?? AppStrings.tr('Consultation'),
        status: (json['status'] as String? ?? 'confirmed').toUpperCase(),
        scheduledAt: json['scheduled_at']?.toString(),
      );
}

/// A window (e.g. 16:00-20:00) the doctor is free on a given date.
class AvailabilityWindow {
  const AvailabilityWindow({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
  final int id;
  final String date;
  final String startTime;
  final String endTime;

  factory AvailabilityWindow.fromJson(Map<String, dynamic> json) =>
      AvailabilityWindow(
        id: json['id'] as int,
        date: json['date'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '09:00',
        endTime: json['end_time'] as String? ?? '17:00',
      );
}

/// Client for doctor portal / dashboard endpoints.
class DoctorService {
  const DoctorService(this._client);
  final ApiClient _client;

  Future<List<QueuePatient>> queue() async {
    final json = await _client.get('/doctors/queue') as List<dynamic>;
    return json
        .map((e) => QueuePatient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Risk-sorted teleconsultation queue (from consultations, demo-mode).
  Future<List<ConsultationQueueItem>> consultationQueue() async {
    final json = await _client.get('/consultations/queue') as List<dynamic>;
    return json
        .map((e) => ConsultationQueueItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mark an existing consultation as in-progress.
  Future<Map<String, dynamic>> startConsultation(int consultationId) async {
    return await _client.post(
          '/consultations/$consultationId/start',
          {},
          authenticated: true,
        )
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> demoStatus() async {
    final json = await _client.get('/demo') as Map<String, dynamic>;
    return (json['patients'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>> simulateBooking({
    required String patientName,
    int? age,
    String? gender,
    String riskLevel = 'HIGH',
    List<String>? symptoms,
  }) async {
    return await _client.post(
      '/demo/consultations',
      {
        'patient_name': patientName,
        'age': age,
        'gender': gender,
        'risk_level': riskLevel,
        'symptoms': symptoms,
      },
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetDemo() async {
    return await _client.post('/demo/reset', {}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    return await _client.get('/doctors/me') as Map<String, dynamic>;
  }

  Future<List<Doctor>> list() async {
    final json = await _client.get('/doctors') as List<dynamic>;
    return json.map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Consultation>> myConsultations() async {
    final json = await _client.get('/consultations') as List<dynamic>;
    return json
        .map((e) => Consultation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createConsultation({
    required int patientUserId,
    String? scheduledAt,
  }) async {
    final json = await _client.post(
      '/consultations',
      {
        'patient_user_id': patientUserId,
        'consultation_type': 'Video Consultation',
        'scheduled_at': scheduledAt,
        'status': 'upcoming',
      },
      authenticated: true,
    ) as Map<String, dynamic>;
    return json;
  }

  Future<Map<String, dynamic>> createPrescription({
    required int consultationId,
    required int patientUserId,
    required String diagnosis,
    required String instructions,
    required List<Map<String, dynamic>> medicines,
  }) async {
    final json = await _client.post(
      '/prescriptions',
      {
        'consultation_id': consultationId,
        'patient_user_id': patientUserId,
        'diagnosis': diagnosis,
        'instructions': instructions,
        'medicines': medicines,
      },
      authenticated: true,
    ) as Map<String, dynamic>;
    return json;
  }

  Future<Map<String, dynamic>> createReferral({
    int? patientUserId,
    required String urgency,
    String? hospital,
    String? specialist,
    String? reason,
  }) async {
    final json = await _client.post(
      '/referrals',
      {
        'patient_user_id': patientUserId,
        'urgency': urgency,
        'hospital': hospital,
        'specialist': specialist,
        'reason': reason,
      },
      authenticated: true,
    ) as Map<String, dynamic>;
    return json;
  }

  /// Patients available for the doctor to schedule a follow-up.
  Future<List<PatientBrief>> patients() async {
    final json = await _client.get('/doctors/patients') as List<dynamic>;
    return json
        .map((e) => PatientBrief.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Booked appointments for this doctor (with patient names).
  Future<List<DoctorAppointment>> appointments() async {
    final json = await _client.get('/doctors/appointments') as List<dynamic>;
    return json
        .map((e) => DoctorAppointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Declare a free window for this doctor.
  Future<Map<String, dynamic>> setAvailability({
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    return await _client.post(
      '/doctors/availability',
      {'date': date, 'start_time': startTime, 'end_time': endTime},
      authenticated: true,
    ) as Map<String, dynamic>;
  }

  /// The doctor's own availability windows (optionally filtered by date).
  Future<List<AvailabilityWindow>> myAvailability({String? date}) async {
    final q = date == null ? '' : '?date=$date';
    final json = await _client.get('/doctors/availability$q') as List<dynamic>;
    return json
        .map((e) => AvailabilityWindow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Books a follow-up appointment for a patient with this doctor.
  Future<Map<String, dynamic>> scheduleAppointment({
    required int doctorId,
    required int patientUserId,
    required String scheduledAt,
    String type = 'Video Consultation',
  }) async {
    return await _client.post(
      '/appointments',
      {
        'doctor_id': doctorId,
        'patient_user_id': patientUserId,
        'scheduled_at': scheduledAt,
        'type': type,
      },
      authenticated: true,
    ) as Map<String, dynamic>;
  }
}