import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around the [SpeechToText] plugin.
///
/// Handles permission requests and exposes a simple start/stop API. On
/// platforms or devices without speech recognition it reports [available]
/// as false so the UI can offer manual text input instead.
class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  String? _lastError;

  /// Whether the platform reported speech recognition as available.
  bool get available => _available;

  /// Whether audio is currently being captured and recognised.
  bool get isListening => _speech.isListening;

  /// The last error message from the speech engine, if any.
  String? get lastError => _lastError;

  /// Initialises the plugin and requests microphone permission.
  /// Returns true when recognition is available.
  Future<bool> initialize() async {
    _lastError = null;
    try {
      _available = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          _lastError = error.errorMsg;
        },
        onStatus: (_) {},
        debugLogging: false,
      );
    } catch (_) {
      _available = false;
      _lastError = 'Speech recognition is not available on this device.';
    }
    return _available;
  }

  /// Starts listening. [onPartial] fires for interim results, [onDone]
  /// fires once with the final transcript. Returns false on failure.
  Future<bool> start({
    required void Function(String text) onPartial,
    required void Function(String text) onDone,
  }) async {
    _lastError = null;
    if (!_available) return false;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          final text = result.recognizedWords;
          if (result.finalResult) {
            onDone(text);
          } else {
            onPartial(text);
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          autoPunctuation: true,
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 6),
          cancelOnError: true,
        ),
      );
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  Future<void> cancel() async {
    if (_speech.isListening) await _speech.cancel();
  }
}
