import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/services/sync_queue.dart';

class SymptomService {
  const SymptomService(this._client);

  final ApiClient _client;

  /// Runs a full symptom check against the backend triage engine.
  ///
  /// [inputType] is "icon" or "voice". Pass whichever input the patient used.
  Future<SymptomCheckResult> analyze({
    required String inputType,
    String text = '',
    List<String> symptoms = const [],
    String? severity,
    String? duration,
  }) async {
    final payload = <String, dynamic>{
      'input_type': inputType,
      'text': text,
      'symptoms': symptoms,
      'severity': severity,
      'duration': duration,
    };

    // Offline-first: if the backend is unreachable, register the check for
    // replay and hand back a result holding that queued status.
    if (!await SyncQueue.instance.isOnline()) {
      await SyncQueue.instance.enqueue('POST', '/symptom-check', payload);
      return const SymptomCheckResult(
        symptoms: [],
        riskScore: 0,
        riskLevel: 'UNKNOWN',
        explanation:
            'You appear to be offline. Your symptom check is saved and will be synced when you reconnect.',
        redFlags: [],
        selfCare: [],
        queued: true,
      );
    }

    final json = await _client.post(
      '/symptom-check',
      payload,
      authenticated: true,
    ) as Map<String, dynamic>;
    return SymptomCheckResult.fromJson(json);
  }
}