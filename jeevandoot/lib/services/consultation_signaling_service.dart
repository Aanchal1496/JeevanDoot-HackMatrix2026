import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_config.dart';

/// A signaling message exchanged with the backend room.
class SignalingMessage {
  const SignalingMessage(this.type, [this.data = const {}]);

  final String type;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {'type': type, ...data};

  factory SignalingMessage.fromJson(Map<String, dynamic> json) =>
      SignalingMessage(
        json['type'] as String? ?? '',
        Map<String, dynamic>.from(json),
      );
}

/// Authentication / connection failure surfaced to the UI.
class SignalingException implements Exception {
  const SignalingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// WebSocket signaling client for a single consultation room.
///
/// - Connects with the auth token (backend validates role + consultation
///   membership server-side; the client never supplies a role/user_id that is
///   trusted).
/// - Auto-reconnects with exponential backoff (1s, 2s, 4s, 8s, 16s... capped)
///   when the socket drops, replacing the old channel rather than stacking
///   duplicate connections.
/// - Emits a broadcast stream for the call controller.
class SignalingService {
  SignalingService({
    required this.consultationId,
    required this.token,
  });

  final String consultationId;
  final String token;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();

  /// Bounded history of non-presence messages, replayed to late listeners.
  /// The waiting room consumes JOINED/USER_JOINED then hands the socket off to
  /// the call screen, and during that hand-off an OFFER/ICE candidate can
  /// arrive with no live listener - a broadcast controller would drop it, so
  /// we keep a short buffer and replay it to each new listener.
  static const int _maxRecent = 64;
  final List<Map<String, dynamic>> _recent = [];

  bool _closing = false;
  bool _reconnectScheduled = false;
  int _attempt = 0;
  Timer? _backoffTimer;

  /// Whether the peer is currently in the room. Updated from JOINED /
  /// USER_JOINED events so that a component which subscribes to [messages]
  /// late (e.g. the call screen, after the waiting room already consumed the
  /// presence events) still knows the peer is present and can start
  /// negotiating without waiting for a message that will never arrive again.
  bool peerPresent = false;

  /// Emits every received signaling message. Each call returns an independent
  /// stream: a new listener first receives the recent buffered messages (so
  /// negotiation messages are never lost during the waiting-room -> call
  /// screen hand-off), then live messages.
  Stream<Map<String, dynamic>> get messages {
    late final StreamController<Map<String, dynamic>> ctrl;
    late final StreamSubscription<Map<String, dynamic>> fwd;
    ctrl = StreamController<Map<String, dynamic>>(
      onListen: () {
        // Subscribe to the source BEFORE replaying, so a message that arrives
        // while the replay runs is captured instead of dropped.
        fwd = _messages.stream.listen(
          (msg) {
            if (!ctrl.isClosed) ctrl.add(msg);
          },
          onDone: () {
            if (!ctrl.isClosed) ctrl.close();
          },
        );
        for (final msg in _recent) {
          if (ctrl.isClosed) return;
          ctrl.add(msg);
        }
      },
      onCancel: () => fwd.cancel(),
    );
    return ctrl.stream;
  }

  bool get isConnected => _channel != null;

  Uri get _uri {
    final base = ApiConfig.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return Uri.parse(
        '$base/api/consultations/session/$consultationId/signaling?token=$token');
  }

  /// Opens (or re-opens) the connection. Completes once the socket is open.
  Future<void> connect() async {
    _closing = false;
    _attempt++;
    try {
      _channel?.sink.close();
    } catch (_) {}
    final channel = WebSocketChannel.connect(_uri);
    _channel = channel;
    await channel.ready;
    _sub = channel.stream.listen(
      _onData,
      onDone: _onClosed,
      onError: (_) => _onClosed(),
    );
    _attempt = 0;
  }

  void _onData(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = decoded['type'];
      if (type == 'JOINED') {
        peerPresent = decoded['peer_present'] == true;
      } else if (type == 'USER_JOINED') {
        peerPresent = true;
      }
      // Presence/lifecycle messages are captured via [peerPresent] and must
      // not be replayed (a stale USER_LEFT would wrongly mark the peer gone).
      if (type != 'JOINED' && type != 'USER_JOINED' && type != 'USER_LEFT') {
        _recent.add(decoded);
        if (_recent.length > _maxRecent) {
          _recent.removeRange(0, _recent.length - _maxRecent);
        }
      }
      if (!_messages.isClosed) _messages.add(decoded);
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _onClosed() {
    _channel = null;
    if (_closing || _reconnectScheduled) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closing) return;
    _reconnectScheduled = true;
    final delay = _backoffDelay();
    _backoffTimer?.cancel();
    _backoffTimer = Timer(delay, () async {
      _reconnectScheduled = false;
      if (_closing) return;
      try {
        await connect();
        _recent.add({'type': '_RECONNECTED'});
        if (_recent.length > _maxRecent) {
          _recent.removeRange(0, _recent.length - _maxRecent);
        }
        if (!_messages.isClosed) {
          _messages.add({'type': '_RECONNECTED'});
        }
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  Duration _backoffDelay() {
    final seconds = [1, 2, 4, 8, 16, 16];
    final idx = _attempt.clamp(0, seconds.length - 1);
    return Duration(seconds: seconds[idx]);
  }

  int get currentAttempt => _attempt;

  /// Sends a signaling message (OFFER/ANSWER/ICE_CANDIDATE/CHAT/...).
  Future<void> send(String type, [Map<String, dynamic> data = const {}]) async {
    final ws = _channel;
    if (ws == null) throw const SignalingException('Not connected.');
    ws.sink.add(jsonEncode({'type': type, ...data}));
  }

  Future<void> close() async {
    _closing = true;
    _backoffTimer?.cancel();
    await _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _messages.close();
  }
}
