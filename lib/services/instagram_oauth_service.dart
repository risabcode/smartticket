import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InstagramOAuthService {
  static const String _baseUrl = 'https://graph.facebook.com/v19.0';

  final String _token = dotenv.env['INSTAGRAM_GRAPH_ACCESS_TOKEN']!;

  // ---------------------------------------------------------------------------
  // CONNECT (TOKEN-ONLY)
  // ---------------------------------------------------------------------------

  /// Validates that the Graph API token exists and works.
  /// Used by SocialHub "Connect Instagram".
  Future<String> connect() async {
    // Try a real API call to validate token
    await getPages();
    return 'graph-token-valid';
  }

  /// Client-side disconnect (no revoke supported)
  Future<void> disconnect() async {
    return;
  }

  // ---------------------------------------------------------------------------
  // GRAPH API CALLS
  // ---------------------------------------------------------------------------

  // 1️⃣ List Facebook Pages
  // GET /me/accounts
  Future<List<Map<String, dynamic>>> getPages() async {
    final url = Uri.parse(
      '$_baseUrl/me/accounts?fields=id,name,tasks&access_token=$_token',
    );

    final res = await http.get(url);
    _check(res);

    return List<Map<String, dynamic>>.from(
      jsonDecode(res.body)['data'],
    );
  }

  // 2️⃣ Get Instagram Business Account
  // GET /{PAGE_ID}?fields=instagram_business_account
  Future<String?> getInstagramBusinessAccount(String pageId) async {
    final url = Uri.parse(
      '$_baseUrl/$pageId?fields=instagram_business_account&access_token=$_token',
    );

    final res = await http.get(url);
    _check(res);

    return jsonDecode(res.body)['instagram_business_account']?['id'];
  }

  // 3️⃣ IG Account Insights
  // GET /{IG_USER_ID}/insights
  Future<Map<String, int>> getIGInsights(String igUserId) async {
    final url = Uri.parse(
      '$_baseUrl/$igUserId/insights'
      '?metric=reach,follower_count'
      '&period=day'
      '&access_token=$_token',
    );

    final res = await http.get(url);
    _check(res);

    final data = jsonDecode(res.body)['data'];

    return {
      for (var item in data)
        item['name']: item['values'][0]['value'] ?? 0,
    };
  }

  // 4️⃣ List Instagram Media
  // GET /{IG_USER_ID}/media
  Future<List<Map<String, dynamic>>> getMedia(String igUserId) async {
    final url = Uri.parse(
      '$_baseUrl/$igUserId/media'
      '?fields=id,caption,media_type,media_url,timestamp'
      '&access_token=$_token',
    );

    final res = await http.get(url);
    _check(res);

    return List<Map<String, dynamic>>.from(
      jsonDecode(res.body)['data'],
    );
  }

  // 5️⃣ Media Insights
  // GET /{MEDIA_ID}/insights
  Future<Map<String, int>> getMediaInsights(String mediaId) async {
    final url = Uri.parse(
      '$_baseUrl/$mediaId/insights'
      '?metric=impressions,reach,engagement,saved'
      '&access_token=$_token',
    );

    final res = await http.get(url);
    _check(res);

    final data = jsonDecode(res.body)['data'];

    return {
      for (var item in data)
        item['name']: item['values'][0]['value'] ?? 0,
    };
  }

  // 6️⃣ Page Insights
  // GET /{PAGE_ID}/insights
  Future<int> getPageMetric(String pageId, String metric) async {
    final url = Uri.parse(
      '$_baseUrl/$pageId/insights'
      '?metric=$metric'
      '&period=day'
      '&access_token=$_token',
    );

    final res = await http.get(url);
    _check(res);

    return jsonDecode(res.body)['data'][0]['values'][0]['value'] ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  void _check(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('Graph API Error: ${res.body}');
    }
  }
}
