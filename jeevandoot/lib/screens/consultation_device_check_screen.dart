import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'consultation_waiting_room_screen.dart';

/// Pre-call device check: camera, microphone, network.
///
/// Failing video never blocks the call - the patient can always continue with
/// audio only (microphone is mandatory for a consultation).
class ConsultationDeviceCheckScreen extends StatefulWidget {
  const ConsultationDeviceCheckScreen({
    super.key,
    required this.consultationId,
    required this.appointmentId,
    required this.role,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.consultType,
  });

  final String consultationId;
  final String appointmentId;
  final String role;
  final String patientName;
  final String patientId;
  final String doctorName;
  final String consultType;

  @override
  State<ConsultationDeviceCheckScreen> createState() =>
      _ConsultationDeviceCheckScreenState();
}

class _ConsultationDeviceCheckScreenState
    extends State<ConsultationDeviceCheckScreen> {
  bool _cameraOk = false;
  bool _micOk = false;
  bool _checking = true;
  String? _cameraHint;
  String? _micHint;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _checking = true;
      _cameraOk = false;
      _micOk = false;
    });

    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        if (mounted) {
          _showNetworkError();
          return;
        }
      }
    } catch (_) {
      if (mounted) {
        _showNetworkError();
        return;
      }
    }

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      var videoInput = false;
      var audioInput = false;
      for (final d in devices) {
        if (d.kind == 'videoinput') videoInput = true;
        if (d.kind == 'audioinput') audioInput = true;
      }
      if (videoInput) {
        try {
          final stream = await navigator.mediaDevices.getUserMedia(
            {'audio': false, 'video': true},
          );
          await stream.dispose();
          _cameraOk = true;
        } catch (_) {
          _cameraHint = 'Camera permission was denied.';
        }
      } else {
        _cameraHint = 'No camera found on this device.';
      }
      if (audioInput) {
        try {
          final stream = await navigator.mediaDevices.getUserMedia(
            {'audio': true, 'video': false},
          );
          await stream.dispose();
          _micOk = true;
        } catch (_) {
          _micHint = 'Microphone permission was denied.';
        }
      } else {
        _micHint = 'No microphone found on this device.';
      }
    } catch (_) {
      // enumerateDevices failed - treat as unavailable but don't block.
    }

    if (!mounted) return;
    setState(() => _checking = false);
  }

  void _showNetworkError() {
    setState(() => _checking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'No internet connection. Please check your network and try again.'),
      ),
    );
  }

  Future<void> _join({required bool withVideo}) async {
    if (!_micOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Microphone permission is required for an audio consultation.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConsultationWaitingRoomScreen(
          consultationId: widget.consultationId,
          role: widget.role,
          patientName: widget.patientName,
          patientId: widget.patientId,
          doctorName: widget.doctorName,
          consultType: widget.consultType,
          startWithVideo: withVideo && _cameraOk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Device Check', style: AppTextStyles.headlineMd),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.campaign, size: 56, color: scheme.primary),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Let\u2019s check your device',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'This only takes a few seconds. If video is unavailable you can still join with audio.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              _checkTile(scheme, Icons.videocam, 'Camera',
                  _checking ? null : _cameraOk, _cameraHint),
              const SizedBox(height: AppSpacing.gutter),
              _checkTile(scheme, Icons.mic, 'Microphone',
                  _checking ? null : _micOk, _micHint),
              const SizedBox(height: AppSpacing.gutter),
              _checkTile(scheme, Icons.wifi, 'Internet',
                  _checking ? null : true, null),
              const Spacer(),
              if (_checking)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (!_cameraOk) ...[
                  Text(
                    _cameraHint ?? 'Camera unavailable',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                ],
                PillButton(
                  label: 'Join with Video',
                  icon: Icons.videocam,
                  onPressed: _cameraOk ? () => _join(withVideo: true) : null,
                ),
                const SizedBox(height: AppSpacing.gutter),
                PillButton(
                  label: 'Join with Audio Only',
                  icon: Icons.headset,
                  backgroundColor: scheme.surfaceContainerLow,
                  foregroundColor: scheme.onSurface,
                  onPressed: _micOk ? () => _join(withVideo: false) : null,
                ),
                const SizedBox(height: AppSpacing.unit),
                TextButton(
                  onPressed: _runChecks,
                  child: const Text('Re-run checks'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkTile(ColorScheme scheme, IconData icon, String label,
      bool? ok, String? hint) {
    final status = ok == null
        ? 'Checking...'
        : (ok ? 'Detected' : 'Unavailable');
    final color = ok == null
        ? scheme.onSurfaceVariant
        : (ok ? const Color(0xFF16A34A) : scheme.error);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface)),
                if (hint != null && ok == false)
                  Text(hint,
                      style: AppTextStyles.labelSm.copyWith(color: scheme.error)),
              ],
            ),
          ),
          Text(status,
              style: AppTextStyles.labelLg.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
