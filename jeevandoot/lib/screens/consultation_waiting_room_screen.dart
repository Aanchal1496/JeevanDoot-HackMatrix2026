import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/consultation_signaling_service.dart';
import '../theme/app_theme.dart';
import 'consultation_screen.dart';

/// Waiting room with real-time presence: the user joins the signaling room
/// here so the peer sees them, and when the peer arrives we move into the
/// consultation automatically.
class ConsultationWaitingRoomScreen extends StatefulWidget {
  const ConsultationWaitingRoomScreen({
    super.key,
    required this.consultationId,
    required this.role,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.consultType,
    required this.startWithVideo,
  });

  final String consultationId;
  final String role;
  final String patientName;
  final String patientId;
  final String doctorName;
  final String consultType;
  final bool startWithVideo;

  @override
  State<ConsultationWaitingRoomScreen> createState() =>
      _ConsultationWaitingRoomScreenState();
}

class _ConsultationWaitingRoomScreenState
    extends State<ConsultationWaitingRoomScreen> {
  SignalingService? _signaling;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _peerPresent = false;
  bool _leaving = false;
  bool _handedOff = false;
  String? _error;

  bool get _isDoctor => widget.role == 'doctor';
  String get _roleLabel => _isDoctor ? 'Patient' : 'Doctor';
  String get _peerName => _isDoctor ? widget.patientName : widget.doctorName;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    // Tear down any previous attempt (its reconnect timers may still be
    // running) before opening a fresh connection.
    final previous = _signaling;
    _signaling = null;
    _sub?.cancel();
    if (previous != null) {
      await previous.close();
    }
    final signaling = SignalingService(
      consultationId: widget.consultationId,
      token: AppState.token,
    );
    _signaling = signaling;
    try {
      await signaling.connect();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'We couldn\u2019t reach the consultation room. Please try again.';
      });
      return;
    }
    _sub = signaling.messages.listen((msg) {
      if (!mounted) return;
      switch (msg['type']) {
        case 'JOINED':
          setState(() => _peerPresent = msg['peer_present'] == true);
        case 'USER_JOINED':
          setState(() => _peerPresent = true);
        default:
          break;
      }
      if (_peerPresent) {
        _enterConsultation();
      }
    });
  }

  void _enterConsultation() {
    if (!mounted || _leaving) return;
    _leaving = true;
    // The call screen takes ownership of the signaling connection from here.
    // Keep it open: this widget will be disposed mid-transition, and closing
    // it then would kill the socket the call is about to negotiate over.
    _handedOff = true;
    final signaling = _signaling;
    _sub?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(
          consultationId: widget.consultationId,
          role: widget.role,
          patientName: widget.patientName,
          patientId: widget.patientId,
          doctorName: widget.doctorName,
          startWithVideo: widget.startWithVideo,
          signaling: signaling!,
        ),
      ),
    );
  }

  Future<void> _leave() async {
    _leaving = true;
    await _signaling?.close();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Only close the connection when we are abandoning the room. If the call
    // screen took ownership, it closes the signaling itself when it finishes.
    if (!_handedOff) _signaling?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _leave,
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave Waiting Room'),
                ),
              ),
              const Spacer(),
              Icon(
                _isDoctor ? Icons.medical_services : Icons.video_call,
                size: 56,
                color: scheme.primary,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                _isDoctor ? 'Waiting for patient...' : 'You\u2019re in the waiting room',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg,
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                '${_isDoctor ? 'Patient' : 'Doctor'}: $_peerName',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Appointment: ${widget.consultType}',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLg,
              ),
              const SizedBox(height: AppSpacing.gutter),
              Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.stackMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      _peerPresent ? Icons.check_circle : Icons.hourglass_top,
                      color: _peerPresent ? scheme.primary : scheme.tertiary,
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: Text(
                        _peerPresent
                            ? '$_roleLabel has joined. Connecting you now...'
                            : 'Waiting for $_roleLabel...',
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              _deviceRow(scheme, Icons.mic, 'Microphone'),
              const SizedBox(height: AppSpacing.stackSm),
              _deviceRow(scheme, Icons.videocam, 'Camera'),
              const SizedBox(height: AppSpacing.stackSm),
              _deviceRow(scheme, Icons.wifi, 'Internet'),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                FilledButton(onPressed: _connect, child: const Text('Retry')),
              ],
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceRow(ColorScheme scheme, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: AppSpacing.gutter),
        Text(label, style: AppTextStyles.bodyMd),
        const Spacer(),
        const Icon(Icons.check_circle, size: 18, color: Colors.green),
      ],
    );
  }
}
