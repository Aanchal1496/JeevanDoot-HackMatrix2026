import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin wrapper around our FastAPI backend.
class ApiClient {
  ApiClient._();

  /// Base URL of the backend. Override at build time with
  /// `--dart-define=API_BASE_URL=http://<host>:8000/api` if the default
  /// LAN IP doesn't match your machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.17:8000/api',
  );
  static const String _tokenKey = 'auth_token';

  static final ApiClient instance = ApiClient._();

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  dynamic _decode(http.Response response) {
    final body = response.body;

    dynamic json;
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map || decoded is List) {
          json = decoded;
        }
      } catch (_) {
        json = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    final message = json is Map
        ? (json['detail'] ?? 'Request failed').toString()
        : 'Request failed';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> post(String path, Map<String, dynamic> data,
      {bool authenticated = false}) async {
    final token = authenticated ? await this.token : null;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> get(String path) async {
    final token = await this.token;
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> data,
      {bool authenticated = true}) async {
    final token = authenticated ? await this.token : null;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }
}