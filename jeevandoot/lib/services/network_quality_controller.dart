import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/consultation_models.dart';

/// Live snapshot of connection metrics surfaced to the diagnostics panel.
class NetworkStats {
  const NetworkStats({
    this.rttMs = 0,
    this.packetLossPercent = 0,
    this.videoWidth = 0,
    this.videoHeight = 0,
    this.fps = 0,
  });

  final double rttMs;
  final double packetLossPercent;
  final int videoWidth;
  final int videoHeight;
  final int fps;

  String get videoLabel =>
      videoHeight > 0 ? '${videoHeight}p' : 'off';
}

/// Centralized adaptive-quality controller. All bandwidth decisions live here
/// (never scattered across UI widgets).
///
/// Classifies the network GOOD / FAIR / POOR / CRITICAL from WebRTC stats and
/// degrades media in this order: bitrate -> resolution -> FPS -> video OFF.
/// Audio is never sacrificed; hysteresis + cooldowns prevent oscillation.
class NetworkQualityController {
  NetworkQualityController({
    required this.peer,
    required this.mode,
    this.localStream,
  });

  final RTCPeerConnection peer;
  final MediaStream? localStream;
  ConsultDataMode mode;

  NetworkQuality quality = NetworkQuality.good;
  bool videoEnabled = true;
  bool audioEnabled = true;
  NetworkStats stats = const NetworkStats();

  int _videoHeight = 360;
  Timer? _pollTimer;
  DateTime _lastChange = DateTime.now();

  static const _pollInterval = Duration(seconds: 2);
  static const _cooldown = Duration(seconds: 8);

  /// Bitrate targets (kbps) per data mode - configurable thresholds, not
  /// hard medical/product requirements.
  static const Map<ConsultDataMode, List<int>> _bitrateTargets = {
    ConsultDataMode.standard: [500, 350, 250, 0],
    ConsultDataMode.dataSaver: [250, 180, 120, 0],
    ConsultDataMode.audioOnly: [0, 0, 0, 0],
  };

  static const Map<NetworkQuality, int> _heightFor = {
    NetworkQuality.good: 360,
    NetworkQuality.fair: 270,
    NetworkQuality.poor: 180,
    NetworkQuality.critical: 0, // video off
  };

  void start() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void setMode(ConsultDataMode newMode) {
    mode = newMode;
    _lastChange = DateTime.now();
    _apply();
  }

  /// Update the camera on/off state externally (user toggle / device lost).
  void setVideoEnabled(bool enabled) {
    videoEnabled = enabled;
    _lastChange = DateTime.now();
    _apply();
  }

  void setAudioEnabled(bool enabled) {
    audioEnabled = enabled;
  }

  Future<void> _poll() async {
    try {
      final report = await peer.getStats();
      _classify(report);
    } catch (_) {
      // Stats unavailable - keep last classification.
    }
  }

  void _classify(List<StatsReport> report) {
    double loss = 0, rtt = 0;
    int bytesSent = 0, packetsSent = 0;
    int width = 0, height = 0, fps = 0;

    for (final s in report) {
      final v = s.values;
      num? n(dynamic x) => x is num ? x : null;
      if (s.type == 'candidate-pair' && v['selected'] == true) {
        rtt = n(v['currentRoundTripTime'])?.toDouble() ?? rtt;
      } else if (s.type == 'remote-inbound-rtp' || s.type == 'inbound-rtp') {
        if ((v['kind'] ?? 'video') == 'video') {
          final pl = n(v['packetsLost'])?.toDouble() ?? 0;
          final ps = n(v['packetsReceived'])?.toDouble() ?? 0;
          if (ps > 0) loss = (pl / ps) * 100;
        }
      } else if (s.type == 'outbound-rtp') {
        if ((v['kind'] ?? 'audio') == 'video') {
          bytesSent = n(v['bytesSent'])?.toInt() ?? 0;
          packetsSent = n(v['packetsSent'])?.toInt() ?? 0;
          width = n(v['frameWidth'])?.toInt() ?? 0;
          height = n(v['frameHeight'])?.toInt() ?? 0;
          fps = n(v['framesPerSecond'])?.toInt() ?? 0;
        }
      }
    }

    stats = NetworkStats(
      rttMs: rtt * 1000,
      packetLossPercent: loss,
      videoWidth: width,
      videoHeight: height,
      fps: fps,
    );

    final next = _classifyNetwork(loss, rtt, bytesSent, packetsSent);
    _maybeApply(next);
  }

  /// Pure classification - unit-testable without a peer connection.
  @visibleForTesting
  NetworkQuality classify(double lossPercent, double rttMs) {
    if (lossPercent > 15 || rttMs > 800) return NetworkQuality.critical;
    if (lossPercent > 8 || rttMs > 350) return NetworkQuality.poor;
    if (lossPercent > 3 || rttMs > 150) return NetworkQuality.fair;
    return NetworkQuality.good;
  }

  NetworkQuality _classifyNetwork(
      double loss, double rtt, int bytesSent, int packetsSent) {
    var next = classify(loss, rtt);
    // Treat silent video as degraded too (frames stopped flowing).
    if (next == NetworkQuality.good &&
        bytesSent > 0 &&
        packetsSent > 0 &&
        stats.fps == 0) {
      next = NetworkQuality.poor;
    }
    return next;
  }

  void _maybeApply(NetworkQuality next) {
    // Hysteresis: only move up one step at a time, and never faster than the
    // cooldown, to avoid quality oscillation.
    final cooledDown =
        DateTime.now().difference(_lastChange) >= _cooldown;
    if (next == quality) return;
    final jumpingUp =
        next.index > quality.index + 1;
    if (!cooledDown || jumpingUp) return;
    quality = next;
    _lastChange = DateTime.now();
    _apply();
  }

  Future<void> _apply() async {
    final videoAllowed = videoEnabled && mode != ConsultDataMode.audioOnly;
    final targetHeight = videoAllowed ? (_heightFor[quality] ?? 0) : 0;
    final bitrate =
        videoAllowed ? (_bitrateTargets[mode]?[quality.index] ?? 0) : 0;

    // Physically stop/start the local camera so "video off" states actually
    // save bandwidth - a bitrate cap alone does not stop the encoder.
    await _setLocalVideoTrackEnabled(targetHeight > 0);

    if (targetHeight == 0) {
      await _setVideoSenderBitrate(0);
      return;
    }

    if (targetHeight != _videoHeight) {
      _videoHeight = targetHeight;
      await _applyVideoResolution(targetHeight);
    }
    await _setVideoSenderBitrate(bitrate * 1000);
  }

  Future<void> _setLocalVideoTrackEnabled(bool enabled) async {
    final stream = localStream;
    if (stream == null) return;
    for (final t in stream.getTracks()) {
      if (t.kind == 'video' && t.enabled != enabled) {
        t.enabled = enabled;
      }
    }
  }

  Future<void> _applyVideoResolution(int height) async {
    final stream = localStream;
    if (stream == null) return;
    final width = (height * 16 / 9).round();
    for (final t in stream.getTracks()) {
      if (t.kind == 'video') {
        try {
          await t.applyConstraints({
            'width': {'ideal': width, 'max': width},
            'height': {'ideal': height, 'max': height},
          });
        } catch (_) {
          // Resolution changes are best-effort; the bitrate cap still helps.
        }
      }
    }
  }

  Future<void> _setVideoSenderBitrate(int bps) async {
    try {
      final senders = await peer.getSenders();
      final sender = senders.where((s) => s.track?.kind == 'video').firstOrNull;
      if (sender == null) return;
      final params = sender.parameters;
      if (params.encodings == null || params.encodings!.isEmpty) return;
      params.encodings![0].maxBitrate = bps;
      await sender.setParameters(params);
    } catch (_) {
      // Sender parameter adjustment is best-effort.
    }
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
