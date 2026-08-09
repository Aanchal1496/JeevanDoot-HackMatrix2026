import 'package:jeevandoot/api/api_client.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final int id;
  final String email;
  final String name;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
      );
}

class AuthService {
  const AuthService(this._client);

  final ApiClient _client;

  Future<User> signIn({required String email, required String password}) async {
    final json = await _client.post(
      '/auth/login',
      {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    await _client.saveToken(json['access_token'] as String);
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _client.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      'role': 'patient',
    }) as Map<String, dynamic>;
    await _client.saveToken(json['access_token'] as String);
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() => _client.clearToken();

  Future<User> fetchMe() async {
    final json = await _client.get('/auth/me') as Map<String, dynamic>;
    return User.fromJson(json);
  }
}