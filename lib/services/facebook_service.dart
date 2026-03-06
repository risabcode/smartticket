// lib/services/facebook_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FacebookService {
  final String graphVersion = 'v18.0';

  /// Load token from .env (dev only)
  String? _envToken() => dotenv.env['FB_ACCESS_TOKEN'];

  /// Generic GET request to Graph API
  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? params,
    String? token,
  }) async {
    final q = <String, String>{};

    // Add any provided params
    if (params != null) q.addAll(params);

    // Use supplied token or fallback to env token
    final accessToken = token ?? _envToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token provided or found in .env');
    }

    q['access_token'] = accessToken;

    final uri = Uri.https('graph.facebook.com', '/$graphVersion/$path', q);

    final resp = await http.get(uri, headers: {'Accept': 'application/json'});

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // Parse error safely
    try {
      return jsonDecode(resp.body);
    } catch (_) {
      throw Exception('Graph API Error ${resp.statusCode}: ${resp.body}');
    }
  }

  // -------------------------------
  // BASIC USER
  // -------------------------------

  /// GET /me?fields=id,name
  Future<Map<String, dynamic>> getMe({String? token}) => _get(
        'me',
        params: {'fields': 'id,name'},
        token: token,
      );

  // -------------------------------
  // PAGES
  // -------------------------------

  /// GET /me/accounts?fields=id,name,access_token
  Future<Map<String, dynamic>> listPages({String? token}) => _get(
        'me/accounts',
        params: {'fields': 'id,name,access_token'},
        token: token,
      );

  /// GET /{PAGE_ID}?fields=instagram_business_account
  Future<Map<String, dynamic>> getInstagramBusinessAccount(
    String pageId, {
    String? token,
  }) =>
      _get(
        pageId,
        params: {'fields': 'instagram_business_account'},
        token: token,
      );

  // -------------------------------
  // INSTAGRAM USER
  // -------------------------------

  /// GET /{IG_USER_ID}/insights?metric=reach,follower_count&period=day
  Future<Map<String, dynamic>> getIgInsights(
    String igUserId, {
    String? token,
  }) =>
      _get(
        '$igUserId/insights',
        params: {
          'metric': 'reach,follower_count',
          'period': 'day',
        },
        token: token,
      );

  /// GET /{IG_USER_ID}/media
  Future<Map<String, dynamic>> listIgMedia(
    String igUserId, {
    String? token,
  }) =>
      _get(
        '$igUserId/media',
        params: {
          'fields': 'id,caption,media_type,media_url,timestamp',
        },
        token: token,
      );

  /// GET /{MEDIA_ID}/insights
  Future<Map<String, dynamic>> mediaInsights(
    String mediaId, {
    String? token,
  }) =>
      _get(
        '$mediaId/insights',
        params: {
          'metric': 'impressions,reach,engagement,saved',
        },
        token: token,
      );

  // -------------------------------
  // PAGE INSIGHTS
  // -------------------------------

  /// GET /{PAGE_ID}/insights?metric=page_impressions&period=day
  Future<Map<String, dynamic>> pageInsights(
    String pageId,
    String metric, {
    String period = 'day', // <-- non-null default
    String? token,
  }) =>
      _get(
        '$pageId/insights',
        params: {
          'metric': metric,
          'period': period,
        },
        token: token,
      );

  /// Convenience helpers:
  Future<Map<String, dynamic>> pageImpressions(
    String pageId, {
    String? token,
  }) =>
      pageInsights(pageId, 'page_impressions', token: token);

  Future<Map<String, dynamic>> pageEngagedUsers(
    String pageId, {
    String? token,
  }) =>
      pageInsights(pageId, 'page_engaged_users', token: token);

  Future<Map<String, dynamic>> pageFans(
    String pageId, {
    String? token,
  }) =>
      pageInsights(pageId, 'page_fans', token: token);
}
