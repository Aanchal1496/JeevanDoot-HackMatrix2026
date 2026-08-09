import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/symptom_result_screen.dart';
import '../services/speech_service.dart';
import '../services/symptom_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/microphone_button.dart';

/// Phase of the voice/text input screen.
enum _Phase { ready, listening, processing, error, review }

/// Step 2 of the symptom checker: real speech-to-text, transcript review,
/// then submission to POST /api/symptom-check.
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({
    super.key,
    this.selectedSymptoms = const {},
    this.startInTextMode = false,
  });

  /// Symptom ids picked from the icon grid (sent to the backend too).
  final Set<String> selectedSymptoms;

  /// Skip straight to the text editor (used when speech is unavailable).
  final bool startInTextMode;

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  final TextEditingController _textController = TextEditingController();
  final SpeechService _speech = SpeechService.instance;

  _Phase _phase = _Phase.ready;
  String _transcript = '';
  String _error = '';
  String? _submitError;
  bool _textMode = false;
  Timer? _finalResultTimer;

  static const List<double> _baseHeights = [0.3, 0.8, 0.5, 0.9, 0.6, 1.0, 0.7, 0.4];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _textMode = widget.startInTextMode;
    if (_textMode) {
      _phase = _Phase.review;
    } else {
      _initSpeech();
    }
  }

  @override
  void dispose() {
    _finalResultTimer?.cancel();
    _waveController.dispose();
    _textController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    setState(() {
      _phase = _Phase.processing;
      _error = '';
    });
    final available = await _speech.initialize();
    if (!mounted) return;
    setState(() {
      if (available) {
        _phase = _Phase.ready;
      } else {
        _error = _friendlySpeechError();
        _phase = _Phase.error;
      }
    });
  }

  String _friendlySpeechError() {
    final raw = (_speech.lastError ?? '').toLowerCase();
    if (raw.contains('permission') || raw.contains('denied')) {
      return 'Microphone permission is required to describe your symptoms by voice. You can enable it in your device settings, or type your symptoms instead.';
    }
    return 'Speech recognition is not available right now. You can retry, or type your symptoms instead.';
  }

  Future<void> _startListening() async {
    if (_phase == _Phase.listening) {
      await _stopListening();
      return;
    }
    setState(() {
      _phase = _Phase.listening;
      _transcript = '';
      _submitError = null;
      _textController.clear();
    });
    final started = await _speech.start(
      onPartial: (text) {
        if (mounted && _phase == _Phase.listening) {
          setState(() => _transcript = text);
        }
      },
      onDone: (text) {
        if (!mounted) return;
        _finalResultTimer?.cancel();
        if (text.trim().isNotEmpty) {
          _enterReview(text);
        } else {
          setState(() {
            _phase = _Phase.ready;
            _error = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("We couldn't hear anything. Please try again."),
            ),
          );
        }
      },
    );
    if (!started && mounted) {
      setState(() {
        _error = _friendlySpeechError();
        _phase = _Phase.error;
      });
    }
  }

  Future<void> _stopListening() async {
    _finalResultTimer?.cancel();
    await _speech.stop();
    // If the engine never delivered a final result, keep whatever partial
    // transcript we have and move to review.
    _finalResultTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _phase != _Phase.listening) return;
      if (_transcript.trim().isNotEmpty) {
        _enterReview(_transcript);
      } else {
        setState(() => _phase = _Phase.ready);
      }
    });
  }

  void _enterReview(String text) {
    setState(() {
      _transcript = text;
      _textController.text = text;
      _phase = _Phase.review;
    });
  }

  void _useTextMode() {
    _speech.cancel();
    setState(() {
      _textMode = true;
      _transcript = '';
      _submitError = null;
      _phase = _Phase.review;
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && widget.selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe at least one symptom.')),
      );
      return;
    }
    setState(() {
      _phase = _Phase.processing;
      _submitError = null;
    });
    try {
      final result = await runSymptomCheck(
        text: text,
        selectedSymptoms: widget.selectedSymptoms.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SymptomResultScreen(result: result)),
      );
    } on SymptomCheckFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.review;
        _submitError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.review;
        _submitError =
            'Something went wrong. Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(scheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  140,
                ),
                child: _body(scheme),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(scheme),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: scheme.onSurface,
        ),
        Expanded(
          child: Text(
            _phase == _Phase.review ? 'Review your symptoms' : 'Describe your symptoms',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLgMobile.copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_phase == _Phase.ready) return _readyState(scheme);
    if (_phase == _Phase.listening) return _listeningState(scheme);
    if (_phase == _Phase.error) return _errorState(scheme);
    if (_phase == _Phase.processing) {
      // Processing is used both while initialising the microphone and
      // while waiting for the backend analysis.
      if (!_textMode && _transcript.isEmpty && _submitError == null) {
        return _processingState(scheme, 'Getting the microphone ready...');
      }
      return _processingState(scheme, 'Analyzing your symptoms...');
    }
    return _reviewState(scheme);
  }

  // -----------------------------------------------------------------------
  // Voice states
  // -----------------------------------------------------------------------

  Widget _readyState(ColorScheme scheme) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.stackLg),
        MicrophoneButton(
          listening: false,
          onPressed: _startListening,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Tap the microphone and tell us how you\u2019re feeling.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'You can speak naturally, in your preferred language.',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLg.copyWith(color: scheme.secondary),
        ),
        if (widget.selectedSymptoms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackLg),
          _selectedChips(scheme),
        ],
      ],
    );
  }

  Widget _listeningState(ColorScheme scheme) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.stackLg),
        MicrophoneButton(
          listening: true,
          onPressed: _stopListening,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        _waveform(scheme),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Listening...',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          "Tap the microphone when you're done.",
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLg.copyWith(color: scheme.secondary),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _transcript.isEmpty
                ? 'Listening for your symptoms...'
                : _transcript,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(
              color: scheme.onSurfaceVariant,
              fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _processingState(ColorScheme scheme, String message) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.stackLg),
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Understanding your symptoms...',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _errorState(ColorScheme scheme) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.stackLg),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.mic_off, size: 44, color: scheme.error),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          _error,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        PillButton(
          label: 'Try again',
          icon: Icons.refresh,
          onPressed: _initSpeech,
        ),
        const SizedBox(height: AppSpacing.unit),
        PillButton(
          label: 'Type your symptoms instead',
          icon: Icons.keyboard,
          backgroundColor: scheme.surfaceContainerHighest,
          foregroundColor: scheme.onSurface,
          onPressed: _useTextMode,
        ),
      ],
    );
  }

  Widget _reviewState(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_submitError != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: scheme.error),
                const SizedBox(width: AppSpacing.unit),
                Expanded(
                  child: Text(
                    _submitError!,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
        ],
        Text(
          'What you told us',
          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        TextField(
          controller: _textController,
          maxLines: 5,
          minLines: 3,
          enabled: _phase != _Phase.processing,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Describe your symptoms...',
          ),
        ),
        if (widget.selectedSymptoms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stackMd),
          _selectedChips(scheme),
        ],
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Review what you said. You can edit it, record again, or submit for analysis.',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _selectedChips(ColorScheme scheme) {
    final labels = widget.selectedSymptoms
        .map(symptomLabel)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected symptoms',
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.unit),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in labels)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelLg.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _waveform(ColorScheme scheme) {
    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < _baseHeights.length; i++) _waveBar(scheme, i),
            ],
          );
        },
      ),
    );
  }

  Widget _waveBar(ColorScheme scheme, int index) {
    final progress = _waveController.value;
    final phase = (index * 0.7 + progress * 2) % 1.0;
    final height = (_baseHeights[index] * 0.4 + 0.6 * phase) * 64;
    return Container(
      width: 8,
      height: height.clamp(8, 64),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(999)),
      ),
    );
  }

  Widget _bottomBar(ColorScheme scheme) {
    if (_phase == _Phase.processing) {
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.gutter,
          AppSpacing.containerMargin,
          16,
        ),
        child: SafeArea(
          top: false,
          child: PillButton(
            label: 'Understanding your symptoms...',
            loading: true,
            onPressed: null,
          ),
        ),
      );
    }
    if (_phase != _Phase.review) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.gutter,
        AppSpacing.containerMargin,
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface.withValues(alpha: 0),
            scheme.surface,
            scheme.surface,
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!_textMode) ...[
              Expanded(
                child: PillButton(
                  label: 'Record again',
                  icon: Icons.mic,
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.onSurface,
                  onPressed: () {
                    setState(() {
                      _phase = _Phase.ready;
                      _transcript = '';
                      _submitError = null;
                    });
                    _startListening();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
            ],
            Expanded(
              child: PillButton(
                label: 'Check my symptoms',
                icon: Icons.health_and_safety,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
