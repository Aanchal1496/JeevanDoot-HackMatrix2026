import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/consultation_models.dart';
import '../services/consultation_api_service.dart';
import '../services/consultation_signaling_service.dart';
import '../services/network_quality_controller.dart';
import '../services/webrtc_call_service.dart';
import '../theme/app_theme.dart';
import 'consultation_completed_screen.dart';

/// The live consultation: video/audio call with adaptive quality, controls,
/// chat, network diagnostics, data-saver mode and reconnection.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    super.key,
    required this.consultationId,
    required this.role,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.startWithVideo,
    required this.signaling,
  });

  final String consultationId;
  final String role;
  final String patientName;
  final String patientId;
  final String doctorName;
  final bool startWithVideo;
  final SignalingService signaling;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  WebRtcCallService? _call;
  RTCVideoView? _remoteView;
  MediaStream? _remoteStream;
  RTCVideoRenderer? _remoteRenderer;
  RTCVideoRenderer? _localRenderer;
  StreamSubscription<Map<String, dynamic>>? _screenSub;

  bool _micOn = true;
  bool _cameraOn = true;
  bool _speakerOn = true;
  bool _peerCameraOn = true;
  bool _ended = false;

  CallPhase _phase = CallPhase.connecting;
  NetworkQuality _quality = NetworkQuality.good;
  NetworkStats _stats = const NetworkStats();
  ConsultDataMode _mode = ConsultDataMode.standard;

  final List<({String from, String text})> _chat = [];
  final TextEditingController _chatCtrl = TextEditingController();
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  Timer? _statsTimer;

  bool get _isDoctor => widget.role == 'doctor';
  String get _peerName => _isDoctor ? widget.patientName : widget.doctorName;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    List<IceServerConfig> iceServers = const [];
    try {
      iceServers = await ConsultationApiService.instance.fetchIceServers();
    } catch (_) {
      // Fall back to empty (native defaults) if the config endpoint fails.
    }
    final call = WebRtcCallService(
      signaling: widget.signaling,
      iceServers: iceServers,
      isOfferer: !_isDoctor,
      callbacks: CallCallbacks(
        onRemoteStream: _onRemoteStream,
        onPhase: _onPhase,
        onQuality: _onQuality,
        onPeerMediaState: _onPeerMediaState,
        onPeerLeft: _onPeerLeft,
        onPeerEnded: _onPeerEnded,
      ),
    );
    _call = call;
    _screenSub = widget.signaling.messages.listen(_onScreenSignaling);
    try {
      await call.join(video: widget.startWithVideo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera or microphone could not be opened. Please try again.'),
        ),
      );
    }
    // Set up the self-preview renderer (async initialize is idempotent).
    final localRenderer = RTCVideoRenderer();
    try {
      await localRenderer.initialize();
      localRenderer.srcObject = call.localStream;
    } catch (_) {
      // Preview is cosmetic; a failure here must never block the call.
    }
    if (!mounted) return;
    setState(() {
      _micOn = call.micOn;
      _cameraOn = call.cameraOn;
      _localRenderer = localRenderer;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _phase == CallPhase.connected) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
    // Refresh the diagnostics stats a few times a second for the panel.
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final q = _call?.quality;
      if (q != null && mounted) setState(() => _stats = q.stats);
    });
  }

  void _onRemoteStream(MediaStream? stream) {
    if (!mounted) return;
    setState(() {
      _remoteStream = stream;
      if (stream == null) {
        _remoteView = null;
        return;
      }
      _remoteRenderer ??= RTCVideoRenderer();
      final renderer = _remoteRenderer!;
      renderer.initialize().then((_) {
        if (mounted) renderer.srcObject = stream;
      });
      _remoteView = RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    });
  }

  void _onPhase(CallPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
  }

  void _onQuality(NetworkQuality quality) {
    if (!mounted) return;
    setState(() => _quality = quality);
  }

  void _onPeerMediaState(bool micOn, bool cameraOn) {
    if (!mounted) return;
    setState(() => _peerCameraOn = cameraOn);
  }

  void _onPeerLeft() {
    if (!mounted || _ended) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The other participant left the consultation.')),
    );
  }

  void _onPeerEnded() {
    if (!mounted || _ended) return;
    _finish(byPeer: true);
  }

  void _onScreenSignaling(Map<String, dynamic> msg) {
    if (!mounted) return;
    switch (msg['type']) {
      case 'CHAT':
        final text = (msg['message'] as String?) ?? '';
        if (text.isNotEmpty) {
          setState(() {
            _chat.add((from: msg['role'] == 'doctor' ? 'Doctor' : 'Patient', text: text));
          });
        }
      case 'MEDIA_STATE_CHANGED':
        _onPeerMediaState(msg['mic_on'] == true, msg['camera_on'] == true);
      default:
        break;
    }
  }

  Future<void> _toggleMic() async {
    final call = _call;
    if (call == null) return;
    final next = !_micOn;
    await call.setMic(next);
    if (mounted) setState(() => _micOn = next);
  }

  Future<void> _toggleCamera() async {
    final call = _call;
    if (call == null) return;
    final next = !_cameraOn;
    await call.setCamera(next);
    if (mounted) setState(() => _cameraOn = next);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    // Speaker toggle (earpiece/speaker) is device-level; WebRTC audio keeps
    // routing to the loudspeaker by default on Android.
  }

  Future<void> _sendChat() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();
    setState(() => _chat.add((from: _isDoctor ? 'Doctor' : 'Patient', text: text)));
    try {
      await widget.signaling.send('CHAT', {'message': text});
    } catch (_) {}
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End consultation?'),
        content: const Text('Are you sure you want to end this consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue Consultation'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('End Consultation'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _finish(byPeer: false);
    }
  }

  Future<void> _finish({required bool byPeer}) async {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    final call = _call;
    _call = null;
    await call?.endCall();
    if (!byPeer) {
      try {
        await widget.signaling.send('CALL_ENDED');
      } catch (_) {}
    }
    await _screenSub?.cancel();
    await widget.signaling.close();

    final qualityLabel = _quality.label;
    final duration = _elapsed;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConsultationCompletedScreen(
            consultationId: widget.consultationId,
            role: widget.role,
            patientName: widget.patientName,
            patientId: widget.patientId,
            doctorName: widget.doctorName,
            duration: duration,
            qualityLabel: qualityLabel,
            peerLeftEarly: byPeer,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statsTimer?.cancel();
    _screenSub?.cancel();
    _chatCtrl.dispose();
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reconnecting = _phase == CallPhase.reconnecting;
    final connecting = _phase == CallPhase.connecting || _phase == CallPhase.idle;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        backgroundColor: scheme.inverseSurface,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _remoteArea(scheme),
            _topBar(scheme),
            _selfPreview(scheme),
            if (connecting) _connectingOverlay(scheme),
            if (reconnecting) _reconnectingOverlay(scheme),
            _controls(scheme),
          ],
        ),
      ),
    );
  }

  Widget _remoteArea(ColorScheme scheme) {
    final remote = _remoteView;
    if (remote != null && _remoteStream != null) {
      return remote;
    }
    // Placeholder while no remote stream (waiting for the peer / camera off).
    return ColoredBox(
      color: scheme.inverseSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 96, color: scheme.onInverseSurface.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              _peerCameraOn ? _peerName : '$_peerName \u2022 Camera Off',
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onInverseSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(ColorScheme scheme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_peerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMd.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Consultation \u2022 ${_fmtDuration(_elapsed)}',
                        style: AppTextStyles.labelSm.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              _qualityBadge(scheme),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _qualityBadge(ColorScheme scheme) {
    final (icon, color, label) = switch (_quality) {
      NetworkQuality.good => (Icons.signal_cellular_alt, const Color(0xFF4ADE80), 'Good'),
      NetworkQuality.fair => (Icons.signal_cellular_alt, const Color(0xFFFACC15), 'Fair'),
      NetworkQuality.poor => (Icons.signal_cellular_off, const Color(0xFFFB923C), 'Poor'),
      NetworkQuality.critical => (Icons.signal_cellular_off, const Color(0xFFF87171), 'Critical'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _selfPreview(ColorScheme scheme) {
    final local = _call?.localStream;
    return Positioned(
      top: 84,
      right: AppSpacing.containerMargin,
      child: Container(
        width: 96,
        height: 132,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: local != null && _cameraOn && _localRenderer != null
            ? RTCVideoView(_localRenderer!,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
            : ColoredBox(
                color: scheme.surfaceContainer,
                child: const Icon(Icons.person, size: 40),
              ),
      ),
    );
  }

  Widget _connectingOverlay(ColorScheme scheme) {
    return Positioned.fill(
      child: ColoredBox(
        color: scheme.inverseSurface.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Connecting...',
                  style: AppTextStyles.headlineMd.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Setting up a secure connection',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reconnectingOverlay(ColorScheme scheme) {
    return Positioned.fill(
      child: ColoredBox(
        color: scheme.inverseSurface.withValues(alpha: 0.92),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 48, color: const Color(0xFFFACC15)),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Connection lost',
                  style: AppTextStyles.headlineMd.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Trying to reconnect...',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white70)),
              const SizedBox(height: AppSpacing.stackLg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _finishNow,
                    child: const Text('End Consultation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finishNow() {
    _finish(byPeer: false);
  }

  Widget _controls(ColorScheme scheme) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin, 0, AppSpacing.containerMargin, AppSpacing.stackMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roundControl(scheme, _micOn ? Icons.mic : Icons.mic_off,
                  tooltip: _micOn ? 'Mute microphone' : 'Unmute microphone',
                  active: _micOn, onTap: _toggleMic),
              const SizedBox(width: AppSpacing.unit),
              _roundControl(scheme, _cameraOn ? Icons.videocam : Icons.videocam_off,
                  tooltip: _cameraOn ? 'Turn camera off' : 'Turn camera on',
                  active: _cameraOn, onTap: _toggleCamera),
              const SizedBox(width: AppSpacing.unit),
              _roundControl(scheme, _speakerOn ? Icons.volume_up : Icons.volume_off,
                  tooltip: 'Speaker', active: _speakerOn, onTap: _toggleSpeaker),
              const SizedBox(width: AppSpacing.unit),
              _roundControl(scheme, Icons.chat_bubble_outline,
                  tooltip: 'Chat', active: true, onTap: _openChat),
              const SizedBox(width: AppSpacing.unit),
              _roundControl(scheme, Icons.settings_outlined,
                  tooltip: 'Settings', active: true, onTap: _openSettings),
              const SizedBox(width: AppSpacing.unit),
              _roundControl(scheme, Icons.network_check,
                  tooltip: 'Connection details', active: true, onTap: _openDiagnostics),
              const SizedBox(width: AppSpacing.stackSm),
              GestureDetector(
                onTap: _confirmEnd,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundControl(ColorScheme scheme, IconData icon,
      {required String tooltip, required bool active, required VoidCallback onTap}) {
    final isToggle = icon == Icons.mic || icon == Icons.mic_off ||
        icon == Icons.videocam || icon == Icons.videocam_off ||
        icon == Icons.volume_up || icon == Icons.volume_off;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isToggle && !active
                ? scheme.error
                : Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 24,
              color: isToggle && !active ? Colors.white : scheme.onSurface),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Chat
  // ------------------------------------------------------------------

  void _openChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Text('Chat', style: AppTextStyles.headlineMd),
              ),
              const Divider(height: 1),
              Expanded(
                child: _chat.isEmpty
                    ? Center(
                        child: Text('No messages yet.\nUse chat for quick updates.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.gutter),
                        itemCount: _chat.length,
                        itemBuilder: (ctx, i) => _chatBubble(ctx, _chat[i]),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _sendChat(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.unit),
                      IconButton.filled(
                        onPressed: _sendChat,
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatBubble(BuildContext ctx, ({String from, String text}) msg) {
    final scheme = Theme.of(ctx).colorScheme;
    final mine = msg.from == (_isDoctor ? 'Doctor' : 'Patient');
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.unit),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.from,
                style: AppTextStyles.labelSm.copyWith(
                    color: mine ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
            Text(msg.text, style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Settings (data usage) + diagnostics
  // ------------------------------------------------------------------

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Data Usage', style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.gutter),
              RadioGroup<ConsultDataMode>(
                groupValue: _mode,
                onChanged: (m) {
                  if (m == null) return;
                  setState(() => _mode = m);
                  _call?.setMode(m);
                  Navigator.of(ctx).pop();
                },
                child: Column(
                  children: [
                    for (final mode in ConsultDataMode.values)
                      RadioListTile<ConsultDataMode>(
                        value: mode,
                        title: Text(mode.label),
                        subtitle: Text(_modeSubtitle(mode)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _modeSubtitle(ConsultDataMode mode) => switch (mode) {
        ConsultDataMode.standard => 'Video up to 360p, 15\u201320 FPS',
        ConsultDataMode.dataSaver => 'Video up to 240p, 10\u201315 FPS, reduced bitrate',
        ConsultDataMode.audioOnly => 'No video, audio prioritised',
      };

  void _openDiagnostics() {
    final s = _stats;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Connection Details', style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.gutter),
              _diagRow('Network', _quality.label),
              _diagRow('RTT', '${s.rttMs.toStringAsFixed(0)} ms'),
              _diagRow('Packet Loss', '${s.packetLossPercent.toStringAsFixed(1)}%'),
              _diagRow('Video', '${s.videoLabel} \u2022 ${s.fps} FPS'),
              _diagRow('Audio', _micOn ? 'Active' : 'Muted'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant)),
          Text(value,
              style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
