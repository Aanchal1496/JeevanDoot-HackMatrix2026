import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/symptom_service.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/triage_result_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum _VoiceStatus { initializing, unsupported, denied, ready, listening, error }

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key, required this.selectedSymptoms});

  final Set<String> selectedSymptoms;

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const List<double> _baseHeights = [0.3, 0.8, 0.5, 0.9, 0.6, 1.0, 0.7, 0.4];

  final SpeechToText _speech = SpeechToText();
  final TextEditingController _textController = TextEditingController();

  _VoiceStatus _status = _VoiceStatus.initializing;
  bool _listening = false;
  bool _submitting = false;
  bool _started = false;
  String _userMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool supported;
    try {
      supported = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _listening = status == 'listening';
            if (status == 'done' && !_started) {
              _started = true;
            }
          });
        },
        onError: (error) => _onSpeechError(error),
      );
    } catch (_) {
      supported = false;
    }
    if (!mounted) return;
    if (!supported) {
      setState(() {
        _status = _VoiceStatus.unsupported;
        _userMessage =
            'Voice input is not supported here. You can type your symptoms below.';
      });
      return;
    }
    setState(() => _status = _VoiceStatus.ready);
    _startListening();
  }

  Future<void> _startListening() async {
    try {
      await _speech.listen(
        onResult: _onResult,
      );
      if (!mounted) return;
      setState(() {
        _status = _VoiceStatus.listening;
        _listening = true;
        _userMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _VoiceStatus.error;
        _userMessage = 'Microphone access is required for voice input. '
            'You can also enter your symptoms manually.';
      });
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    _textController.text = result.recognizedWords;
    setState(() {});
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _status = _VoiceStatus.error;
      _userMessage = error.permanent
          ? 'Voice input is not available. Please type your symptoms below.'
          : 'We could not hear any speech. Please try again or type your symptoms.';
    });
  }

  Future<void> _stopAndSubmit() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    if (!mounted) return;
    final text = _textController.text.trim();
    if (text.isEmpty && widget.selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select at least one symptom.'),
        ),
      );
      setState(() => _userMessage =
          'No symptoms entered. Please speak, type, or go back to select symptoms.');
      return;
    }
    if (text.isEmpty) {
      // Icon-only input -> send with empty text.
    }
    await _submit(text);
  }

  Future<void> _submit(String text) async {
    setState(() => _submitting = true);
    try {
      final result = await SymptomService(ApiClient.instance).analyze(
        inputType: text.isNotEmpty ? 'voice' : 'icon',
        text: text,
        symptoms: widget.selectedSymptoms.toList(),
      );
      if (!mounted) return;
      _speech.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => TriageResultScreen(result: result)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to analyze your symptoms right now. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: scheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  120,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      _statusTitle(scheme).keys.first,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLgMobile.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      _statusTitle(scheme).values.first,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    _micRipple(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    if (_listening || _status == _VoiceStatus.ready)
                      _waveform(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    _transcription(scheme),
                    if (_userMessage.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.stackMd),
                      _messageBanner(scheme),
                    ],
                    if (widget.selectedSymptoms.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.stackMd),
                      _selectedChips(scheme),
                    ],
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      "Tap the microphone to listen, or type your symptoms.",
                      style: AppTextStyles.labelLg
                          .copyWith(color: scheme.secondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(scheme),
    );
  }

  Map<String, String> _statusTitle(ColorScheme scheme) {
    if (_status == _VoiceStatus.unsupported || _status == _VoiceStatus.denied) {
      return {"title": "Voice unavailable", "subtitle": "Type your symptoms below."};
    }
    if (_status == _VoiceStatus.error && !_listening) {
      return {
        "title": "Couldn't capture your voice",
        "subtitle": "Try again or type your symptoms.",
      };
    }
    return {
      "title": "Listening...",
      "subtitle": _listening ? 'Speak now' : "Please speak or type",
    };
  }

  Widget _messageBanner(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _userMessage,
        style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
      ),
    );
  }

  Widget _micRipple(ColorScheme scheme) {
    return SizedBox(
      width: 192,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final delay in const [
            Duration.zero,
            Duration(milliseconds: 500),
            Duration(milliseconds: 1000),
          ])
            _RippleCircle(
              color: scheme.primaryContainer,
              controller: _controller,
              delay: delay,
            ),
          InkWell(
            onTap: _listening ? _stopListening : _startListening,
            customBorder: const CircleBorder(),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _listening ? scheme.primary : scheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _listening ? Icons.stop : Icons.mic,
                size: 40,
                color: _listening ? AppColors.onPrimary : scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    setState(() => _listening = false);
  }

  Widget _waveform(ColorScheme scheme) {
    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: _controller,
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
    final progress = _controller.value;
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

  Widget _transcription(ColorScheme scheme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        onChanged: (_) => setState(() {}),
        maxLines: 3,
        minLines: 2,
        style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Describe your symptoms...',
          hintStyle: AppTextStyles.bodyLg.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _selectedChips(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in widget.selectedSymptoms)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              kSymptoms.firstWhere((s) => s.id == id,
                  orElse: () => Symptom(id, id, Icons.medical_services)).label,
              style: AppTextStyles.labelLg
                  .copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
      ],
    );
  }

  Widget _bottomBar(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
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
            Expanded(
              child: PillButton(
                label: _submitting ? 'Analyzing...' : 'Done',
                icon: Icons.check,
                onPressed: _submitting ? null : _stopAndSubmit,
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: PillButton(
                label: 'Clear',
                icon: Icons.refresh,
                backgroundColor: scheme.surfaceContainerHighest,
                foregroundColor: scheme.onSurface,
                onPressed: _listening ? _stopListening : _clearText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _userMessage = '';
      _startListening();
    });
  }
}

class _RippleCircle extends StatelessWidget {
  const _RippleCircle({
    required this.color,
    required this.controller,
    required this.delay,
  });

  final Color color;
  final Animation<double> controller;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = ((controller.value * 1000 - delay.inMilliseconds) % 1000) / 1000;
        final scale = 1.0 + t * 0.9;
        final opacity = (1 - t) * 0.5;
        return Container(
          width: 192,
          height: 192,
          transform: Matrix4.diagonal3Values(scale, scale, 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}