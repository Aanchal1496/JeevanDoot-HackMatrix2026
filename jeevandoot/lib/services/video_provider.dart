/// Result of joining a consultation room.
class VideoJoinResult {
  const VideoJoinResult({required this.success, this.message});

  final bool success;
  final String? message;
}

/// Connection state of a live consultation session.
enum VideoConnectionState { connecting, connected, ended }

/// Abstraction over the teleconsultation media provider.
///
/// Today the app ships with [SimulatedTeleconsultationProvider] because no
/// real media infrastructure is configured. To integrate WebRTC, Agora,
/// Twilio or Daily later, implement this interface and swap the instance in
/// [TeleconsultationVideoProvider.instance] — no screen code needs to change.
abstract class TeleconsultationVideoProvider {
  String get providerName;

  /// Joins the room for [meetingId]. Resolves once the media connection is up.
  Future<VideoJoinResult> join({
    required String meetingId,
    required bool audioOnly,
  });

  /// Leaves the current room and releases resources.
  Future<void> leave();
}

/// Local simulated provider: fakes a connecting → connected handshake so the
/// full room UX (status, controls, join/leave) works end to end without a
/// media server.
class SimulatedTeleconsultationProvider implements TeleconsultationVideoProvider {
  const SimulatedTeleconsultationProvider();

  @override
  String get providerName => 'Simulated';

  @override
  Future<VideoJoinResult> join({
    required String meetingId,
    required bool audioOnly,
  }) async {
    // Simulated network handshake.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    return VideoJoinResult(
      success: true,
      message: 'Connected to room $meetingId',
    );
  }

  @override
  Future<void> leave() async {}
}

/// The provider used across the patient app. Swap this for a real provider
/// (Agora / Twilio / Daily / WebRTC) without touching any screen.
abstract final class TeleconsultationVideoProviderFactory {
  static TeleconsultationVideoProvider _instance =
      const SimulatedTeleconsultationProvider();

  static TeleconsultationVideoProvider get instance => _instance;

  static void override(TeleconsultationVideoProvider provider) {
    _instance = provider;
  }
}
