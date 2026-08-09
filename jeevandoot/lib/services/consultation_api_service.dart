import '../models/consultation_models.dart';
import 'api_client.dart';

/// REST calls for the consultation lifecycle. The WebSocket signaling lives in
/// [SignalingService] (consultation_signaling_service.dart) and media in
/// [WebRtcCallService] (webrtc_call_service.dart).
class ConsultationApiService {
  ConsultationApiService._();

  static final ConsultationApiService instance = ConsultationApiService._();

  /// Creates (or returns) the consultation for an appointment and returns it.
  Future<Consultation> createForAppointment({
    required String appointmentId,
    required String requesterRole,
  }) async {
    final res = await ApiClient.instance.post(
      '/api/consultations',
      {'appointment_id': appointmentId, 'requester_role': requesterRole},
      timeout: const Duration(seconds: 15),
    ) as Map;
    return Consultation.fromJson(
      (res['consultation'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Consultation> fetch(String consultationId) async {
    final res = await ApiClient.instance
        .get('/api/consultations/$consultationId') as Map;
    return Consultation.fromJson(
      (res['consultation'] as Map).cast<String, dynamic>(),
    );
  }

  /// Marks the consultation COMPLETED with duration + quality summary.
  Future<Consultation> end({
    required String consultationId,
    int? durationSeconds,
    String? connectionQuality,
  }) async {
    final res = await ApiClient.instance.post(
      '/api/consultations/$consultationId/end',
      {
        'duration_seconds': durationSeconds,
        'connection_quality': connectionQuality,
      },
    ) as Map;
    return Consultation.fromJson(
      (res['consultation'] as Map).cast<String, dynamic>(),
    );
  }

  /// Fetches the ICE server list (STUN + optional TURN from backend env).
  Future<List<IceServerConfig>> fetchIceServers() async {
    final res = await ApiClient.instance
        .get('/api/consultations/turn-config') as Map;
    return (res['ice_servers'] as List? ?? const [])
        .map((e) => IceServerConfig.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

/// Convenience: turn an appointment record (from the appointments API) into
/// something the consultation flow can display.
class ConsultationAppointment {
  const ConsultationAppointment({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.consultType,
    required this.status,
    required this.time,
    this.patientId,
  });

  final String id;
  final String name;
  final String doctorName;
  final String consultType;
  final String status;
  final String time;
  final String? patientId;

  bool get isVideo => consultType.contains('Video');
  bool get isUpcoming => status != 'Completed' && status != 'CANCELLED';
}
