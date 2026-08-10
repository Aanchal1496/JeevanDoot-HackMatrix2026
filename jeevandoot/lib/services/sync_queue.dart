import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jeevandoot/api/api_client.dart';

enum SyncStatus { online, syncing, offline, synced, failed }

/// One queued mutation that should be replayed against the backend once the
/// device is back online.
class PendingOp {
  const PendingOp({
    required this.method,
    required this.path,
    required this.data,
    this.createdAt,
  });

  final String method;
  final String path;
  final Map<String, dynamic> data;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
        'method': method,
        'path': path,
        'data': data,
        'created_at': createdAt ?? DateTime.now().toIso8601String(),
      };

  factory PendingOp.fromJson(Map<String, dynamic> json) => PendingOp(
        method: json['method'] as String? ?? 'POST',
        path: json['path'] as String? ?? '/',
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: json['created_at'] as String?,
      );
}

/// A small offline-first queue. Mutations are persisted on-device and replayed
/// when connectivity returns. Reads are not queued (they need a live response).
class SyncQueue extends ChangeNotifier {
  SyncQueue._();

  static final SyncQueue instance = SyncQueue._();
  static const String _queueKey = 'offline_queue_v1';

  final ApiClient _client = ApiClient.instance;
  List<PendingOp> _queue = const [];
  SyncStatus _status = SyncStatus.online;
  String? _lastError;

  SyncStatus get status => _status;
  List<PendingOp> get pending => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  String? get lastError => _lastError;

  /// Fire-and-forget best-effort connectivity probe.
  Future<bool> isOnline() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiClient.baseUrl}/health'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Store a mutation to replay later. Returns the current queued count.
  Future<int> enqueue(String method, String path,
      Map<String, dynamic> data) async {
    final op = PendingOp(method: method, path: path, data: data);
    _queue = [..._queue, op];
    _setStatus(SyncStatus.offline);
    await _persist();
    return _queue.length;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _queueKey,
      jsonEncode(_queue.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) {
      _queue = const [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _queue = list
          .map((e) => PendingOp.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _queue = const [];
    }
  }

  /// Prompted startup restore.
  Future<void> init() async {
    await _restore();
    _status = await isOnline()
        ? (_queue.isEmpty ? SyncStatus.online : SyncStatus.syncing)
        : SyncStatus.offline;
    notifyListeners();
  }

  /// Attempt to flush queued mutations to the backend.
  Future<SyncStatus> syncNow() async {
    if (!await isOnline()) {
      _setStatus(SyncStatus.offline);
      return SyncStatus.offline;
    }
    _setStatus(SyncStatus.syncing);
    final remaining = <PendingOp>[];
    for (final op in _queue) {
      try {
        switch (op.method.toUpperCase()) {
          case 'PUT':
            await _client.put(op.path, op.data, authenticated: true);
            break;
          case 'POST':
          default:
            await _client.post(op.path, op.data, authenticated: true);
        }
      } catch (e) {
        // Keep it queued so it can be retried; mark the batch as failed.
        remaining.add(op);
        _lastError ??= e.toString();
      }
    }
    _queue = remaining;
    _lastError = remaining.isEmpty ? null : _lastError;
    await _persist();
    final next = _queue.isEmpty ? SyncStatus.synced : SyncStatus.failed;
    _setStatus(next);
    return next;
  }

  /// Drop everything that failed (user override).
  Future<void> clear() async {
    _queue = const [];
    _lastError = null;
    await _persist();
    _setStatus(await isOnline() ? SyncStatus.online : SyncStatus.offline);
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }
}