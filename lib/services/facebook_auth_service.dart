// lib/services/facebook_auth_service.dart
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FacebookAuthService {
  static const _kTokenKey = 'fb_access_token';
  static final _storage = const FlutterSecureStorage();

  /// Attempts to get a valid token:
  /// 1. Checks current SDK AccessToken (if user already logged in)
  /// 2. If not present, tries to read stored token (fallback)
  /// 3. If still none, triggers login flow
  static Future<String?> ensureToken({bool forceLogin = false}) async {
    try {
      // 1) If SDK has an active token (and not forced), use it
      final current = await FacebookAuth.instance.accessToken;
      if (!forceLogin && current != null && !current.isExpired) {
        final token = current.token;
        await _storage.write(key: _kTokenKey, value: token);
        return token;
      }

      // 2) Try secure storage (may exist from previous run)
      final stored = await _storage.read(key: _kTokenKey);
      if (!forceLogin && stored != null) {
        // Note: can't validate expiry locally; prefer SDK token if available
        return stored;
      }

      // 3) Otherwise, perform login
      final loginResult = await FacebookAuth.instance.login(
        permissions: [
          'public_profile',
          'pages_show_list',
          'pages_read_engagement',
          'instagram_basic',
          'instagram_manage_insights',
        ],
      );

      if (loginResult.status == LoginStatus.success) {
        final token = loginResult.accessToken!.token;
        await _storage.write(key: _kTokenKey, value: token);
        return token;
      } else {
        // cancelled or failed
        return null;
      }
    } catch (e) {
      // swallow and return null; caller will handle errors
      return null;
    }
  }

  /// Clears stored token + SDK logout
  static Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    await _storage.delete(key: _kTokenKey);
  }
}
