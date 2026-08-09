import 'package:jeevandoot/api/api_client.dart';

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
}