import 'dart:convert';
import 'package:http/http.dart' as http;

class FetchLiveDataService {
  /// Fetch IG Business profile + media (paginated)
  /// Token: Facebook Graph API token (EAASk...)
  Future<Map<String, dynamic>> fetchInitial({
    required String accessToken,
    int mediaLimit = 9,
  }) async {
    try {
      // 1️⃣ Resolve Instagram Business Account ID
      final igUserId = await _resolveIgBusinessId(accessToken);
      if (igUserId == null) {
        return {
          'error': 'Instagram business account not linked to this token',
          'data': null,
          'next': null,
        };
      }

      // 2️⃣ Profile
      final profileUri = Uri.parse(
        'https://graph.facebook.com/v17.0/$igUserId'
        '?fields=id,username,profile_picture_url,followers_count,media_count'
        '&access_token=$accessToken',
      );

      final profileRes = await http.get(profileUri);
      if (profileRes.statusCode != 200) {
        return {
          'error': 'Profile fetch failed: ${profileRes.body}',
          'data': null,
          'next': null,
        };
      }

      final profile = jsonDecode(profileRes.body) as Map<String, dynamic>;

      // 3️⃣ Media (posts)
      final mediaUri = Uri.parse(
        'https://graph.facebook.com/v17.0/$igUserId/media'
        '?fields=id,caption,media_type,media_url,thumbnail_url,permalink,timestamp,like_count,comments_count'
        '&limit=$mediaLimit'
        '&access_token=$accessToken',
      );

      final mediaRes = await http.get(mediaUri);
      if (mediaRes.statusCode != 200) {
        return {
          'error': 'Media fetch failed: ${mediaRes.body}',
          'data': null,
          'next': null,
        };
      }

      final decoded = jsonDecode(mediaRes.body) as Map<String, dynamic>;
      final media = decoded['data'] ?? [];
      final next = decoded['paging']?['next'];

      return {
        'error': null,
        'data': {
          'profile': profile,
          'media': media,
          'igUserId': igUserId,
        },
        'next': next,
      };
    } catch (e) {
      return {'error': e.toString(), 'data': null, 'next': null};
    }
  }

  /// Pagination
  Future<Map<String, dynamic>> fetchPage(String nextUrl) async {
    try {
      final res = await http.get(Uri.parse(nextUrl));
      if (res.statusCode != 200) {
        return {'error': res.body, 'media': [], 'next': null};
      }
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'error': null,
        'media': decoded['data'] ?? [],
        'next': decoded['paging']?['next'],
      };
    } catch (e) {
      return {'error': e.toString(), 'media': [], 'next': null};
    }
  }

  /// Media-level insights (THIS IS WHERE BUSINESS TOKEN SHINES)
  Future<Map<String, dynamic>> fetchMediaInsights({
    required String accessToken,
    required String mediaId,
  }) async {
    try {
      final metrics = 'impressions,reach,engagement,saved,likes,comments';
      final uri = Uri.parse(
        'https://graph.facebook.com/v17.0/$mediaId/insights'
        '?metric=$metrics&access_token=$accessToken',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        return {'error': res.body, 'data': null};
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      return {'error': null, 'data': decoded['data'] ?? []};
    } catch (e) {
      return {'error': e.toString(), 'data': null};
    }
  }

  /// Resolve IG Business ID from the token
  Future<String?> _resolveIgBusinessId(String token) async {
    final uri = Uri.parse(
      'https://graph.facebook.com/v17.0/me/accounts'
      '?fields=instagram_business_account'
      '&access_token=$token',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final decoded = jsonDecode(res.body);
    final pages = decoded['data'] as List<dynamic>?;

    if (pages == null) return null;

    for (final p in pages) {
      final ig = p['instagram_business_account'];
      if (ig != null && ig['id'] != null) {
        return ig['id'].toString();
      }
    }
    return null;
  }
}
