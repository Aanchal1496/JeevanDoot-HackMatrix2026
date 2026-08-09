import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// A client-side error thrown when the backend is unreachable or returns
/// an unexpected response. Screens surface this message in snackbars.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin JSON client over [http] pointing at [ApiConfig.baseUrl].
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  String? token;

  Duration get _timeout => const Duration(seconds: 8);

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint,
      {Map<String, String>? query, bool raw = false}) async {
    var uri = ApiConfig.path(endpoint);
    if (query != null && query.isNotEmpty) {
      final parts = query.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      uri = '$uri?$parts';
    }
    try {
      final res = await http.get(Uri.parse(uri), headers: _headers()).timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Could not reach the server. Is the backend running?');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {bool json = true}) async {
    try {
      final res = await http
          .post(Uri.parse(ApiConfig.path(endpoint)),
              headers: _headers(json: json),
              body: json ? jsonEncode(body) : null)
          .timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Is the backend running?');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(Uri.parse(ApiConfig.path(endpoint)),
              headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Is the backend running?');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await http
          .patch(Uri.parse(ApiConfig.path(endpoint)),
              headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Is the backend running?');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final res = await http
          .delete(Uri.parse(ApiConfig.path(endpoint)), headers: _headers())
          .timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Is the backend running?');
    }
  }

  /// Downloads raw bytes (e.g. a prescription PDF) with auth headers.
  Future<List<int>> download(String endpoint) async {
    try {
      final res = await http
          .get(Uri.parse(ApiConfig.path(endpoint)), headers: _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res.bodyBytes;
      }
      throw ApiException(
        'Download failed (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Is the backend running?');
    }
  }

  dynamic _decode(http.Response res) {
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final detail = (decoded is Map && decoded['detail'] != null)
        ? decoded['detail'].toString()
        : 'Request failed (${res.statusCode}).';
    throw ApiException(detail, statusCode: res.statusCode);
  }
}
