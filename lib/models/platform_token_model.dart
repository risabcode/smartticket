class PlatformTokenModel {
  final String platform; // 'youtube', 'facebook', etc.
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiry;

  PlatformTokenModel({
    required this.platform,
    required this.accessToken,
    this.refreshToken,
    this.expiry,
  });
}
