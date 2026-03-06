import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookOAuthService {
  /// Opens Facebook login and returns access token
  Future<String?> connect() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: [
          'public_profile',
          'email',
          'pages_show_list',
          'pages_read_engagement',
          'instagram_basic',
        ],
      );

      if (result.status != LoginStatus.success) {
        return null;
      }

      return result.accessToken?.token;
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnect() async {
    await FacebookAuth.instance.logOut();
  }
}
