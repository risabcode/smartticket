import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlatformProvider extends ChangeNotifier {
  // Supported platforms (Facebook + Instagram only)
  final Map<String, bool> _connected = {
    'facebook': false,
    'instagram': false,
  };

  final Map<String, String?> _tokens = {
    'facebook': null,
    'instagram': null,
  };

  // Meta app credentials (NOT persisted)
  String? _metaAppId;
  String? _metaAppSecret;

  String? _selectedPlatform;

  PlatformProvider() {
    _loadFromPrefs(); // fire-and-forget init load
  }

  // ------------------ GETTERS ------------------

  bool isConnected(String platform) => _connected[platform] ?? false;

  /// Returns list of all connected platforms
  List<String> get connectedPlatforms {
    return _connected.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
  }

  /// Returns true if at least one platform is connected
  bool get isAnyConnected {
    return _connected.values.any((v) => v == true);
  }

  /// Currently selected platform (used by Dashboard / Insights)
  String? get selectedPlatform => _selectedPlatform;

  /// Returns stored token for a platform (or null)
  String? getToken(String platform) => _tokens[platform];

  /// Convenience getter for Instagram token
  String? get instagramAccessToken => _tokens['instagram'];

  /// Meta App credentials
  String? get metaAppId => _metaAppId;
  String? get metaAppSecret => _metaAppSecret;

  // ------------------ META APP SETUP ------------------

  /// Set Meta App credentials (do NOT persist)
  void setMetaAppCredentials({
    required String appId,
    required String appSecret,
  }) {
    _metaAppId = appId;
    _metaAppSecret = appSecret;
  }

  // ------------------ PERSISTENCE ------------------

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in _tokens.keys) {
      final token = prefs.getString('token_$key');
      _tokens[key] = token;
      _connected[key] = token != null;
    }

    // If no selection, pick first connected
    if (_selectedPlatform == null && connectedPlatforms.isNotEmpty) {
      _selectedPlatform = connectedPlatforms.first;
    }

    notifyListeners();
  }

  /// Set connection status of a platform, optionally storing token
  Future<void> setConnected(
    String platform,
    bool value, {
    String? token,
  }) async {
    if (!_connected.containsKey(platform)) return;

    final prefs = await SharedPreferences.getInstance();

    _connected[platform] = value;

    if (value) {
      if (token != null && token.isNotEmpty) {
        _tokens[platform] = token;
        await prefs.setString('token_$platform', token);
      }
      _selectedPlatform ??= platform;
    } else {
      _tokens[platform] = null;
      await prefs.remove('token_$platform');

      if (_selectedPlatform == platform) {
        _selectedPlatform =
            connectedPlatforms.isNotEmpty ? connectedPlatforms.first : null;
      }
    }

    notifyListeners();
  }

  /// Shortcut for connecting Instagram with token
  Future<void> connectInstagram(String token) async {
    await setConnected('instagram', true, token: token);
  }

  /// Shortcut for disconnecting Instagram
  Future<void> disconnectInstagram() async {
    await setConnected('instagram', false);
  }

  /// Toggle connection state
  Future<void> togglePlatform(String platform) async {
    if (!_connected.containsKey(platform)) return;

    await setConnected(
      platform,
      !_connected[platform]!,
      token: !_connected[platform]! ? _tokens[platform] : null,
    );
  }

  /// Disconnect all platforms — useful when user logs out
  Future<void> disconnectAll() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in _connected.keys) {
      _connected[key] = false;
      _tokens[key] = null;
      await prefs.remove('token_$key');
    }

    _selectedPlatform = null;
    notifyListeners();
  }

  /// Set the selected platform (only if it's connected or null)
  set selectedPlatform(String? platform) {
    if (platform == null) {
      _selectedPlatform = null;
      notifyListeners();
      return;
    }

    if (_connected[platform] == true) {
      _selectedPlatform = platform;
      notifyListeners();
    }
  }
}
