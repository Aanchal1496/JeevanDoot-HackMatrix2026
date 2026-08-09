import '../models/symptom_result.dart';
import 'api_client.dart';

/// Failure kinds surfaced by [runSymptomCheck] so the UI can show a
/// specific, helpful message for each situation.
enum SymptomCheckFailureKind { connection, timeout, invalid, server }

class SymptomCheckFailure implements Exception {
  const SymptomCheckFailure(this.kind, this.message);

  final SymptomCheckFailureKind kind;
  final String message;

  @override
  String toString() => message;
}

/// Calls POST /api/symptom-check on the JeevanDoot backend.
///
/// The risk score is always computed by the backend - the app only sends
/// the transcript text and the icon selections.
Future<SymptomResult> runSymptomCheck({
  required String text,
  required List<String> selectedSymptoms,
}) async {
  dynamic decoded;
  try {
    // The backend waits for the AI explanation (up to ~10s), so give this
    // request a much longer budget than the default 8s client timeout.
    decoded = await ApiClient.instance.post('/api/symptom-check', {
      'text': text.trim(),
      'selected_symptoms': selectedSymptoms,
    }, timeout: const Duration(seconds: 30));
  } on ApiException catch (e) {
    final isTimeout = e.statusCode == 408;
    if (isTimeout) {
      throw const SymptomCheckFailure(
        SymptomCheckFailureKind.timeout,
        'The health assistant took too long to respond. Please try again.',
      );
    }
    if (e.statusCode == null) {
      throw const SymptomCheckFailure(
        SymptomCheckFailureKind.connection,
        'Unable to connect to the health assistant. Please check your internet connection.',
      );
    }
    throw SymptomCheckFailure(SymptomCheckFailureKind.server, e.message);
  }

  if (decoded is! Map<String, dynamic>) {
    throw const SymptomCheckFailure(
      SymptomCheckFailureKind.invalid,
      'The health assistant returned an unexpected response. Please try again.',
    );
  }
  try {
    return SymptomResult.fromJson(decoded);
  } catch (_) {
    throw const SymptomCheckFailure(
      SymptomCheckFailureKind.invalid,
      'The health assistant returned an unexpected response. Please try again.',
    );
  }
}
