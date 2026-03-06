import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  /// 🔗 LIVE BACKEND
  static const String baseUrl = 'https://smartticket.in';

  /// 🔑 SharedPreferences Keys
  static const _keyToken = 'api_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';

  /// ------------------------------------------------------------
  /// LOGIN
  /// ------------------------------------------------------------
  Future<UserModel?> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/mobile/login');

    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body);

      /// ✅ Laravel uses `status`, NOT `success`
      if (body['status'] != true ||
          body['token'] == null ||
          body['user'] == null) {
        return null;
      }

      final token = body['token'] as String;
      final userJson = Map<String, dynamic>.from(body['user']);

      final user = UserModel(
        id: userJson['id'].toString(),
        name: userJson['name'] ?? '',
        email: userJson['email'] ?? '',
        apiToken: token,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUserId, user.id);
      await prefs.setString(_keyUserName, user.name);
      await prefs.setString(_keyUserEmail, user.email);

      return user;
    } catch (_) {
      return null;
    }
  }

  /// ------------------------------------------------------------
  /// REGISTER
  /// ------------------------------------------------------------
  Future<UserModel?> register(
    String name,
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl/api/mobile/register');

    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        return null;
      }

      final body = jsonDecode(res.body);

      if (body['status'] != true) {
        return null;
      }

      /// 🔁 Auto-login after register
      return await login(email, password);
    } catch (_) {
      return null;
    }
  }

  /// ------------------------------------------------------------
  /// GET SAVED TOKEN
  /// ------------------------------------------------------------
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// ------------------------------------------------------------
  /// LOAD STORED USER
  /// ------------------------------------------------------------
  Future<UserModel?> loadStoredUser() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(_keyUserId);
    final name = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);
    final token = prefs.getString(_keyToken);

    if (id == null || email == null || token == null) return null;

    return UserModel(
      id: id,
      name: name ?? '',
      email: email,
      apiToken: token,
    );
  }

  /// ------------------------------------------------------------
  /// LOGOUT (NO TOKEN PARAMETER)
  /// ------------------------------------------------------------
  Future<void> logout() async {
    try {
      final token = await getSavedToken();

      if (token != null) {
        final uri = Uri.parse('$baseUrl/api/mobile/logout');
        await http.post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {
      // Ignore network errors
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}
