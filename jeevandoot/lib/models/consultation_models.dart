/// Models for the teleconsultation (video/audio call) feature.
library;

/// A consultation session created from an appointment. The backend is the
/// source of truth; this mirrors its payload.
class Consultation {
  const Consultation({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.connectionQuality,
  });

  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String status;
  final String? startedAt;
  final String? endedAt;
  final int? durationSeconds;
  final String? connectionQuality;

  bool get isCompleted => status == 'COMPLETED';
  bool get isWaiting => status == 'WAITING' || status == 'SCHEDULED';

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation(
        id: json['id'] as String? ?? '',
        appointmentId: json['appointment_id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        doctorId: json['doctor_id'] as String? ?? '',
        status: json['status'] as String? ?? 'SCHEDULED',
        startedAt: json['started_at'] as String?,
        endedAt: json['ended_at'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
        connectionQuality: json['connection_quality'] as String?,
      );
}

/// Data-mode preference for a consultation (per-call unless saved globally).
enum ConsultDataMode {
  standard,
  dataSaver,
  audioOnly;

  String get label => switch (this) {
        ConsultDataMode.standard => 'Standard',
        ConsultDataMode.dataSaver => 'Data Saver',
        ConsultDataMode.audioOnly => 'Audio Only',
      };
}

/// Network quality classification used by the adaptive bandwidth controller.
enum NetworkQuality {
  good,
  fair,
  poor,
  critical;

  String get label => switch (this) {
        NetworkQuality.good => 'Good',
        NetworkQuality.fair => 'Fair',
        NetworkQuality.poor => 'Poor',
        NetworkQuality.critical => 'Critical',
      };
}

/// ICE server configuration fetched from the backend (TURN creds never baked
/// into the app).
class IceServerConfig {
  const IceServerConfig({required this.urls, this.username, this.credential});

  final List<String> urls;
  final String? username;
  final String? credential;

  factory IceServerConfig.fromJson(Map<String, dynamic> json) =>
      IceServerConfig(
        urls: (json['urls'] as List?)?.cast<String>() ?? const [],
        username: json['username'] as String?,
        credential: json['credential'] as String?,
      );
}
