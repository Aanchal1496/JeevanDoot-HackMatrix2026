import 'package:jeevandoot/api/api_client.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    this.relationship,
    this.dob,
    this.gender,
    this.bloodGroup,
  });

  final int id;
  final String name;
  final String? relationship;
  final String? dob;
  final String? gender;
  final String? bloodGroup;

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
        id: json['id'] as int,
        name: json['name'] as String,
        relationship: json['relationship_type'] as String?,
        dob: json['date_of_birth']?.toString(),
        gender: json['gender'] as String?,
        bloodGroup: json['blood_group'] as String?,
      );
}

class AppointmentItem {
  const AppointmentItem({
    required this.id,
    this.patientUserId,
    this.doctorId,
    this.scheduledAt,
    this.type,
    this.status,
  });

  final int id;
  final int? patientUserId;
  final int? doctorId;
  final String? scheduledAt;
  final String? type;
  final String? status;

  factory AppointmentItem.fromJson(Map<String, dynamic> json) => AppointmentItem(
        id: json['id'] as int,
        patientUserId: json['patient_user_id'] as int?,
        doctorId: json['doctor_id'] as int?,
        scheduledAt: json['scheduled_at']?.toString(),
        type: json['type'] as String?,
        status: json['status']?.toString(),
      );
}

class Prescription {
  const Prescription({
    required this.id,
    required this.diagnosis,
    required this.medicines,
    this.doctorName,
    this.instructions,
    this.createdAt,
  });

  final int id;
  final String diagnosis;
  final List<Medicine> medicines;
  final String? doctorName;
  final String? instructions;
  final String? createdAt;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as int,
        diagnosis: json['diagnosis'] as String? ?? '',
        medicines: (json['medicines'] as List<dynamic>? ?? [])
            .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
            .toList(),
        doctorName: json['doctor_name'] as String?,
        instructions: json['instructions'] as String?,
        createdAt: json['created_at']?.toString(),
      );
}

class Medicine {
  const Medicine({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.timing,
    this.beforeAfterFood,
  });

  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? timing;
  final String? beforeAfterFood;

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        name: json['medicine_name'] as String,
        dosage: json['dosage'] as String?,
        frequency: json['frequency'] as String?,
        duration: json['duration'] as String?,
        timing: json['timing'] as String?,
        beforeAfterFood: json['before_after_food'] as String?,
      );
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.type,
  });

  final int id;
  final String title;
  final String message;
  final bool read;
  final String? type;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        read: json['read'] as bool? ?? false,
        type: json['type']?.toString(),
      );
}

class Vital {
  const Vital({
    this.bloodPressure,
    this.temperature,
    this.weight,
    this.pulse,
    this.oxygenSaturation,
    this.recordedAt,
  });

  final String? bloodPressure;
  final double? temperature;
  final double? weight;
  final int? pulse;
  final double? oxygenSaturation;
  final String? recordedAt;

  factory Vital.fromJson(Map<String, dynamic> json) => Vital(
        bloodPressure: json['blood_pressure'] as String?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        pulse: json['pulse'] as int?,
        oxygenSaturation: (json['oxygen_saturation'] as num?)?.toDouble(),
        recordedAt: json['recorded_at']?.toString(),
      );
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.recordType,
    required this.title,
    this.description,
    this.fileUrl,
    this.createdAt,
  });

  final int id;
  final String recordType;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? createdAt;

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
        id: json['id'] as int,
        recordType: json['record_type'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        fileUrl: json['file_url'] as String?,
        createdAt: json['created_at']?.toString(),
      );
}

/// Client for patient-scoped endpoints.
class PatientService {
  const PatientService(this._client);

  final ApiClient _client;

  Future<List<FamilyMember>> listFamilyMembers() async {
    final json =
        await _client.get('/family-members') as List<dynamic>;
    return json
        .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FamilyMember> addFamilyMember(Map<String, dynamic> data) async {
    final json = await _client.post(
        '/family-members', data, authenticated: true) as Map<String, dynamic>;
    return FamilyMember.fromJson(json);
  }

  Future<List<AppointmentItem>> listAppointments() async {
    final json = await _client.get('/appointments') as List<dynamic>;
    return json
        .map((e) => AppointmentItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentItem> bookAppointment(
      {required int doctorId,
      required String scheduledAt,
      String type = 'Video Consultation',
      int? familyMemberId}) async {
    final json = await _client.post(
      '/appointments',
      {
        'doctor_id': doctorId,
        'scheduled_at': scheduledAt,
        'type': type,
        'family_member_id': familyMemberId,
      },
      authenticated: true,
    ) as Map<String, dynamic>;
    return AppointmentItem.fromJson(json);
  }

  Future<List<Prescription>> listPrescriptions() async {
    final json = await _client.get('/prescriptions') as List<dynamic>;
    return json
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationItem>> listNotifications() async {
    final json = await _client.get('/notifications') as List<dynamic>;
    return json
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(int id) =>
      _client.put('/notifications/$id/read', const {});

  Future<List<Vital>> listVitals() async {
    final json = await _client.get('/patients/me/vitals') as List<dynamic>;
    return json
        .map((e) => Vital.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HealthRecord>> listHealthRecords() async {
    final json = await _client.get('/patients/me/health-records') as List<dynamic>;
    return json
        .map((e) => HealthRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}