import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/consultation_models.dart';
import 'consultation_signaling_service.dart';
import 'network_quality_controller.dart';

/// Call phases used by the consultation screen state machine.
enum CallPhase {
  idle,
  connecting,
  connected,
  degraded,
  reconnecting,
  ended,
}

/// Outbound callbacks consumed by the consultation screen.
class CallCallbacks {
  const CallCallbacks({
    this.onRemoteStream,
    this.onPhase,
    this.onQuality,
    this.onPeerMediaState,
    this.onPeerLeft,
    this.onPeerEnded,
  });

  final ValueChanged<MediaStream?>? onRemoteStream;
  final ValueChanged<CallPhase>? onPhase;
  final ValueChanged<NetworkQuality>? onQuality;
  final void Function(bool micOn, bool cameraOn)? onPeerMediaState;
  final VoidCallback? onPeerLeft;
  final VoidCallback? onPeerEnded;
}

/// WebRTC peer connection lifecycle for a single consultation.
///
/// - The patient is the OFFERER (creates the SDP offer); the doctor answers.
/// - ICE candidates flow over the signaling WebSocket.
/// - Media constraints start conservative (640x360 @ 15-20fps) and are
///   throttled further by [NetworkQualityController].
/// - Audio is always prioritised over video.
/// - Never re-creates duplicate peer connections: reconnection tears the old
///   connection down before building a new one.
class WebRtcCallService {
  WebRtcCallService({
    required this.signaling,
    required this.iceServers,
    required this.isOfferer,
    this.callbacks = const CallCallbacks(),
  });

  final SignalingService signaling;
  final List<IceServerConfig> iceServers;
  final bool isOfferer;
  final CallCallbacks callbacks;

  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  StreamSubscription<Map<String, dynamic>>? _signalingSub;
  NetworkQualityController? _quality;

  bool _micOn = true;
  bool _cameraOn = true;
  bool _peerPresent = false;
  bool _ending = false;
  bool _renegotiating = false;
  bool _sentOffer = false;
  bool _remoteDescSet = false;

  /// An OFFER that arrived before our peer connection was ready (the peer can
  /// start negotiating before we finish joining). Answered once the
  /// connection exists.
  Map<String, dynamic>? _pendingOffer;

  /// ICE candidates that arrived before [setRemoteDescription] - they are only
  /// valid once the remote description is applied, so they are buffered.
  final List<RTCIceCandidate> _pendingIce = [];

  ConsultDataMode mode = ConsultDataMode.standard;
  CallPhase phase = CallPhase.idle;

  MediaStream? get localStream => _localStream;
  NetworkQualityController? get quality => _quality;

  static const Map<String, dynamic> _videoConstraints = {
    'width': {'ideal': 640, 'max': 640},
    'height': {'ideal': 360, 'max': 360},
    'frameRate': {'ideal': 15, 'max': 20},
  };

  Future<MediaStream> startLocalMedia({bool video = true}) async {
    if (_localStream != null) return _localStream!;
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? _videoConstraints : false,
    });
    _localStream = stream;
    return stream;
  }

  /// Establishes the peer connection and subscribes to signaling.
  Future<void> join({bool video = true}) async {
    if (_localStream == null) {
      await startLocalMedia(video: video);
    }
    if (!video) _cameraOn = false;
    // The peer may already be in the room - the JOINED/USER_JOINED messages
    // were consumed by the waiting room, so read the snapshot held by the
    // signaling service instead of waiting for a message that will never
    // arrive on this broadcast stream again.
    _peerPresent = signaling.peerPresent;
    _sentOffer = false;
    _signalingSub?.cancel();
    _signalingSub = signaling.messages.listen(_onSignaling);
    await _createPeer();
    if (_peerPresent) {
      await _maybeSendOffer();
    }
    // An OFFER can arrive while we are still creating the peer (the peer
    // started negotiating before we finished joining) - handle it now.
    final pending = _pendingOffer;
    if (pending != null) {
      _pendingOffer = null;
      await _handleOffer(pending);
    }
    phase = CallPhase.connecting;
    callbacks.onPhase?.call(phase);
  }

  Future<void> _createPeer() async {
    await _destroyPeer();
    _remoteDescSet = false;
    _pendingIce.clear();
    final config = {
      'iceServers': iceServers
          .map((s) => {
                'urls': s.urls,
                if (s.username != null) 'username': s.username,
                if (s.credential != null) 'credential': s.credential,
              })
          .toList(),
    };
    final peer = await createPeerConnection(config);
    _peer = peer;

    peer.onIceCandidate = (candidate) {
      unawaited(
        signaling
            .send('ICE_CANDIDATE', {'candidate': candidate.toMap()})
            .catchError((_) {}),
      );
    };
    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        callbacks.onRemoteStream?.call(event.streams.first);
      }
    };
    peer.onConnectionState = (state) {
      if (_ending) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _setPhase(CallPhase.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _setPhase(CallPhase.reconnecting);
      }
    };
    peer.onIceConnectionState = (state) {
      if (!_ending &&
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _setPhase(CallPhase.reconnecting);
      }
    };

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await peer.addTrack(track, stream);
      }
    }

    _quality = NetworkQualityController(
        peer: peer, mode: mode, localStream: _localStream)
      ..setVideoEnabled(_cameraOn)
      ..setAudioEnabled(_micOn)
      ..start();
  }

  void _setPhase(CallPhase p) {
    if (_ending) return;
    phase = p;
    callbacks.onPhase?.call(p);
  }

  Future<void> _onSignaling(Map<String, dynamic> msg) async {
    final type = msg['type'] as String? ?? '';
    switch (type) {
      case 'USER_JOINED':
        _peerPresent = true;
        await _maybeSendOffer();
        break;
      case 'JOINED':
        _peerPresent = msg['peer_present'] == true;
        await _maybeSendOffer();
        break;
      case 'OFFER':
        await _handleOffer(msg);
        break;
      case 'ANSWER':
        await _handleAnswer(msg);
        break;
      case 'ICE_CANDIDATE':
        await _handleIce(msg);
        break;
      case 'MEDIA_STATE_CHANGED':
        final mic = msg['mic_on'] == true;
        final cam = msg['camera_on'] == true;
        callbacks.onPeerMediaState?.call(mic, cam);
        break;
      case 'CALL_ENDED':
        callbacks.onPeerEnded?.call();
        break;
      case 'USER_LEFT':
        if (!_ending) callbacks.onPeerLeft?.call();
        break;
      case '_RECONNECTED':
        await _handleSignalingRestored();
        break;
      default:
        break;
    }
  }

  Future<void> _maybeSendOffer() async {
    if (!isOfferer || _sentOffer || _peer == null || !_peerPresent) return;
    _sentOffer = true;
    try {
      await _negotiate();
    } catch (_) {
      // Transient signaling failure (e.g. socket briefly down) - allow the
      // offer to be retried on the next presence/restore event.
      _sentOffer = false;
    }
  }

  Future<void> _handleSignalingRestored() async {
    if (_ending) return;
    // The socket came back after a drop - rebuild the peer connection so we
    // never keep a stale one, then re-negotiate with the peer.
    await _createPeer();
    _peerPresent = signaling.peerPresent;
    _sentOffer = false;
    callbacks.onRemoteStream?.call(null);
    _setPhase(CallPhase.reconnecting);
    final pending = _pendingOffer;
    if (pending != null) {
      _pendingOffer = null;
      await _handleOffer(pending);
    }
    if (_peerPresent) {
      await _maybeSendOffer();
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> msg) async {
    final peer = _peer;
    if (peer == null) {
      // Peer connection is not ready yet (we may still be joining or
      // reconnecting) - buffer the offer and answer once it exists.
      _pendingOffer = msg;
      return;
    }
    await peer.setRemoteDescription(
        RTCSessionDescription(msg['sdp'] as String? ?? '', 'offer'));
    _remoteDescSet = true;
    await _flushPendingIce();
    final answer = await peer.createAnswer();
    await peer.setLocalDescription(answer);
    await signaling.send('ANSWER', {'sdp': answer.sdp});
  }

  Future<void> _handleAnswer(Map<String, dynamic> msg) async {
    final peer = _peer;
    if (peer == null) return;
    await peer.setRemoteDescription(
        RTCSessionDescription(msg['sdp'] as String? ?? '', 'answer'));
    _remoteDescSet = true;
    await _flushPendingIce();
  }

  Future<void> _handleIce(Map<String, dynamic> msg) async {
    final peer = _peer;
    if (peer == null) return;
    final cand = msg['candidate'] as Map<String, dynamic>?;
    if (cand == null) return;
    final ice = RTCIceCandidate(
      cand['candidate'] as String? ?? '',
      cand['sdpMid'] as String?,
      (cand['sdpMLineIndex'] as num?)?.toInt(),
    );
    // Candidates received before setRemoteDescription are ignored by the
    // native stack, so buffer them until the remote description is applied.
    if (!_remoteDescSet) {
      _pendingIce.add(ice);
      return;
    }
    await peer.addCandidate(ice);
  }

  Future<void> _flushPendingIce() async {
    final peer = _peer;
    if (peer == null || !_remoteDescSet) return;
    final pending = List<RTCIceCandidate>.from(_pendingIce);
    _pendingIce.clear();
    for (final ice in pending) {
      await peer.addCandidate(ice);
    }
  }

  Future<void> _negotiate() async {
    if (_renegotiating || _peer == null) return;
    _renegotiating = true;
    try {
      final offer = await _peer!.createOffer();
      await _peer!.setLocalDescription(offer);
      await signaling.send('OFFER', {'sdp': offer.sdp});
    } finally {
      _renegotiating = false;
    }
  }

  // ------------------------------------------------------------------
  // Controls
  // ------------------------------------------------------------------

  Future<void> setMic(bool on) async {
    _micOn = on;
    for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      if (t.kind == 'audio') {
        t.enabled = on;
      }
    }
    _quality?.setAudioEnabled(on);
    await signaling.send('MEDIA_STATE_CHANGED', {
      'mic_on': on,
      'camera_on': _cameraOn,
    });
  }

  Future<void> setCamera(bool on) async {
    _cameraOn = on;
    for (final t in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      if (t.kind == 'video') {
        t.enabled = on;
      }
    }
    _quality?.setVideoEnabled(on);
    await signaling.send('MEDIA_STATE_CHANGED', {
      'mic_on': _micOn,
      'camera_on': on,
    });
  }

  Future<void> setMode(ConsultDataMode m) async {
    mode = m;
    _quality?.setMode(m);
    if (m == ConsultDataMode.audioOnly && _cameraOn) {
      await setCamera(false);
    }
    await signaling.send('MEDIA_STATE_CHANGED', {
      'mic_on': _micOn,
      'camera_on': _cameraOn,
    });
  }

  bool get micOn => _micOn;
  bool get cameraOn => _cameraOn;

  // ------------------------------------------------------------------
  // Teardown
  // ------------------------------------------------------------------

  Future<void> _destroyPeer() async {
    _quality?.dispose();
    _quality = null;
    final peer = _peer;
    _peer = null;
    if (peer != null) {
      await peer.close();
    }
  }

  /// Stops the call and releases camera/mic. Safe to call multiple times.
  Future<void> endCall() async {
    if (_ending) return;
    _ending = true;
    await _destroyPeer();
    await _signalingSub?.cancel();
    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
    }
    phase = CallPhase.ended;
  }
}
