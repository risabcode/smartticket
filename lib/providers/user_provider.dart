import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final AuthService _auth = AuthService();

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get token => _user?.apiToken;

  // ------------------------------------------------------------
  // SET USER (after login / register)
  // ------------------------------------------------------------
  Future<void> setUser(UserModel user) async {
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    if (user.apiToken != null) {
      await prefs.setString('api_token', user.apiToken!);
    }
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);

    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD USER (persistent login)
  // ------------------------------------------------------------
  Future<void> loadUser() async {
    final loaded = await _auth.loadStoredUser();
    if (loaded != null) {
      _user = loaded;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> clearUser({bool callApi = true}) async {
    _user = null;
    notifyListeners();

    if (callApi) {
      // ✅ NO TOKEN PASSED
      await _auth.logout();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
    }
  }
}
