import 'package:flutter/material.dart';
import 'package:jeevandoot/services/video_provider.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

/// Patient-side video/audio consultation room.
///
/// Media is provided through [TeleconsultationVideoProvider] — currently a
/// simulated provider, replaceable with a real WebRTC/Agora/Twilio/Daily
/// backend without changing this screen.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    this.doctorName,
    this.specialization,
    this.photoUrl,
    this.meetingId,
    this.isAudioOnly = false,
  });

  final String? doctorName;
  final String? specialization;
  final String? photoUrl;
  final String? meetingId;
  final bool isAudioOnly;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final TeleconsultationVideoProvider _provider =
      TeleconsultationVideoProviderFactory.instance;

  bool _micOn = true;
  bool _cameraOn = true;
  bool _speakerOn = true;
  VideoConnectionState _connection = VideoConnectionState.connecting;
  String? _connectionError;

  static const String _defaultDoctorImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuArYswFEKWUqY6KXPcK8lNOQPAuiHgksqnGPPxSQ576fLmtElUQtFDiY5tgllEsL6FBt71O2wcpcApw58B-pH3u4Mjqzvbgv2LlOXcneQ5YfGLGJqYUCq9y16ag6EoVYJ6Gn756klumOMkCLcpIsq1npMbPJQBZn9b3pz_91pZMaazsndp79KXLcOrRXZ34duBvYZaBfiqxfr-FTv_5d-5Lf55SlWROK3T2JC0VkPPlbmRiTMmn-Unk';
  static const String _patientImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCU72s8GQlG85GiW4WATEhPVsz2LOvGlpA5IzQGGVfj2kcd5CH9g6yXEsVfqs21w9_YYo0Giit4zs51fw22FObFZJElmDGjGDImhaNSyzNDnLYeu9dw_TahWgsCL-LkX1h8GFpkPEKpIPFuzJKmidt8bTC_GhUxh_p7-d0rUuWVUd-fWxXRZQ59PA4wmaiL0jjzLJHhEVwPkw1_-PXKGNkKrBjOuo8ENsNdaYzmAhjuBA3tVcK0C3uO';

  String get _doctorName => widget.doctorName ?? 'Dr. Priya Sharma';
  String get _specialization => widget.specialization ?? 'General Physician';
  String get _photoUrl =>
      widget.photoUrl == null || widget.photoUrl!.isEmpty
          ? _defaultDoctorImageUrl
          : widget.photoUrl!;
  String get _meetingId => widget.meetingId ?? 'MEET-000000';

  @override
  void initState() {
    super.initState();
    _join();
  }

  @override
  void dispose() {
    _provider.leave();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => _connection = VideoConnectionState.connecting);
    final result = await _provider.join(
      meetingId: _meetingId,
      audioOnly: widget.isAudioOnly,
    );
    if (!mounted) return;
    setState(() {
      if (result.success) {
        _connection = VideoConnectionState.connected;
      } else {
        _connection = VideoConnectionState.ended;
        _connectionError = result.message ?? 'Could not connect to the consultation.';
      }
    });
  }

  void _endCall() {
    Navigator.of(context).pop();
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
            Expanded(flex: 3, child: _videoArea(scheme)),
            if (widget.isAudioOnly)
              Expanded(flex: 2, child: _audioPanel(scheme))
            else
              Expanded(flex: 2, child: _patientPanel(scheme)),
          ],
        ),
      ),
    );
  }

  // -- Header ---------------------------------------------------------------

  Widget _header(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                _photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHigh, child: const Icon(Icons.person)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
                Text(
                  _specialization,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          _connectionBadge(scheme),
        ],
      ),
    );
  }

  Widget _connectionBadge(ColorScheme scheme) {
    final (color, label, icon) = switch (_connection) {
      VideoConnectionState.connecting => (scheme.warningColor, 'Connecting…', Icons.sync),
      VideoConnectionState.connected => (scheme.primary, 'Good', Icons.signal_cellular_alt),
      VideoConnectionState.ended => (scheme.error, 'Ended', Icons.call_end),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_connection == VideoConnectionState.connecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelLg.copyWith(color: color)),
        ],
      ),
    );
  }

  // -- Video area ------------------------------------------------------------

  Widget _videoArea(ColorScheme scheme) {
    if (_connection == VideoConnectionState.connecting) {
      return _connectingState(scheme);
    }
    if (_connection == VideoConnectionState.ended) {
      return _endedState(scheme);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceContainerHighest),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.onSurface.withValues(alpha: 0.6), Colors.transparent],
            ),
          ),
        ),
        if (!widget.isAudioOnly)
          Positioned(
            top: 12,
            right: AppSpacing.containerMargin,
            child: Container(
              width: 96,
              height: 128,
              decoration: BoxDecoration(
                color: scheme.surfaceDim,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.surface, width: 2),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
              ),
              clipBehavior: Clip.antiAlias,
              child: _cameraOn
                  ? Image.network(
                      _patientImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(color: scheme.surfaceDim),
                    )
                  : ColoredBox(
                      color: scheme.surfaceDim,
                      child: const Icon(Icons.person, size: 40),
                    ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackSm,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.surfaceContainerHighest),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isAudioOnly) ...[
                  _control(
                    scheme,
                    icon: _micOn ? Icons.mic : Icons.mic_off,
                    active: _micOn,
                    onTap: () => setState(() => _micOn = !_micOn),
                  ),
                  const SizedBox(width: 8),
                  _control(
                    scheme,
                    icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                    active: _cameraOn,
                    onTap: () => setState(() => _cameraOn = !_cameraOn),
                  ),
                  const SizedBox(width: 8),
                ],
                _control(
                  scheme,
                  icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                  active: _speakerOn,
                  onTap: () => setState(() => _speakerOn = !_speakerOn),
                ),
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: scheme.outlineVariant,
                ),
                _control(
                  scheme,
                  icon: Icons.call_end,
                  active: false,
                  color: scheme.error,
                  iconColor: scheme.onError,
                  onTap: _endCall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _endedState(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call_end, size: 32, color: scheme.error),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              _connectionError ?? 'Consultation ended',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.gutter),
            PillButton(
              label: 'Close',
              height: 48,
              onPressed: _endCall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectingState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PulsingRing(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.isAudioOnly ? Icons.headphones : Icons.videocam,
                size: 44,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'Connecting to $_doctorName…',
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            'Secure consultation • $_meetingId',
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _audioPanel(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
        AppSpacing.containerMargin,
        AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, -10), blurRadius: 40),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _micOn ? scheme.primaryContainer : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _micOn ? Icons.mic : Icons.mic_off,
              size: 32,
              color: _micOn ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            _micOn ? 'You are on audio call' : 'Microphone muted',
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _control(
                scheme,
                icon: _micOn ? Icons.mic : Icons.mic_off,
                active: _micOn,
                onTap: () => setState(() => _micOn = !_micOn),
              ),
              const SizedBox(width: AppSpacing.gutter),
              _control(
                scheme,
                icon: Icons.call_end,
                active: false,
                color: scheme.error,
                iconColor: scheme.onError,
                onTap: _endCall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _control(
    ColorScheme scheme, {
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    final bg = color ?? scheme.surfaceContainerHigh;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 24, color: iconColor ?? scheme.onSurface),
      ),
    );
  }

  // -- Lower panel ------------------------------------------------------------

  Widget _patientPanel(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
        AppSpacing.containerMargin,
        AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, -10), blurRadius: 40),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultation',
                style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
              ),
              Icon(Icons.info, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Expanded(
            child: ListView(
              children: [
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, color: scheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Private & secure',
                            style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        'This consultation is end-to-end encrypted. Your doctor can see your consultation reason and any attachments you shared while booking.',
                        style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.video_call_outlined, color: scheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Meeting $_meetingId',
                            style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Provider: ${_provider.providerName}',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on ColorScheme {
  Color get warningColor => const Color(0xFFF59E0B);
}
