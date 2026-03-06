// lib/services/instagram_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InstagramService {
  /// Base API url (no trailing slash)
  static const String _defaultBaseUrl = 'https://smartticket.in';
  final String baseUrl;
  final AuthService _auth;
  final http.Client _http;

  InstagramService({
    AuthService? auth,
    http.Client? httpClient,
    String? baseUrl,
  })  : _auth = auth ?? AuthService(),
        _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  // ---------------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------------
  Future<Map<String, String>> _headers() async {
    final token = await _auth.getSavedToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated - token missing');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _ensureMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    throw Exception('Expected JSON object but got ${v.runtimeType}');
  }

  List<dynamic> _ensureList(dynamic v) {
    if (v is List) return v;
    throw Exception('Expected JSON array but got ${v.runtimeType}');
  }

  /// Parse response and be flexible about wrapper shapes.
  /// If API returns { status: true, data: ..., paging: ... } we return the full Map
  /// so callers can access both 'data' and 'paging'. If API returns a simple {status:true, data: [...]}
  /// we return the inner data (List/Map) for convenience.
  Future<dynamic> _parseJsonResponse(http.Response res) async {
    final body = res.body;
    if (body.isEmpty) {
      throw Exception('Empty response body (status ${res.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (e) {
      throw Exception('Invalid JSON response (status ${res.statusCode}): $e');
    }

    // If API uses wrapper {status: true, data: ...}
    if (decoded is Map && decoded.containsKey('status')) {
      if (decoded['status'] != true) {
        final message = decoded['message'] ?? decoded['error'] ?? 'API returned an error';
        throw Exception(message.toString());
      }

      // If wrapper contains keys beyond just 'status' and 'data' (e.g. paging, insights),
      // return the whole decoded map so caller can access them.
      final otherKeys = decoded.keys.where((k) => k != 'status' && k != 'message' && k != 'error' && k != 'ok').toList();
      if (otherKeys.length == 1 && otherKeys.first == 'data') {
        // simple wrapper -> return data directly
        return decoded['data'];
      }
      // return whole decoded object (contains data + other metadata like paging)
      return decoded;
    }

    return decoded;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    if (query == null || query.isEmpty) {
      return Uri.parse('$baseUrl$normalized');
    }
    final q = query.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: q);
  }

  // ---------------------------------------------------------------------------
  // 📱 FULL DASHBOARD
  // GET /api/mobile/dashboard
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchDashboard() async {
    final uri = _uri('/api/mobile/dashboard');

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load dashboard (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // parsed can be either:
    //  - Map with {status:true, data: {...}, ...}  -> _parseJsonResponse returns the full map
    //  - or inner data map (if server returned only {status:true,data:{...}})
    if (parsed is Map && parsed.containsKey('data')) {
      return _ensureMap(parsed['data']);
    } else if (parsed is Map) {
      return _ensureMap(parsed);
    }

    throw Exception('Invalid dashboard payload');
  }

  // ---------------------------------------------------------------------------
  // 📸 INSTAGRAM ACCOUNTS
  // GET /api/mobile/instagram/accounts
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> fetchAccounts() async {
    final uri = _uri('/api/mobile/instagram/accounts');

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      // fallback to dashboard (best-effort) if server hiccup
      if (res.statusCode >= 500) {
        try {
          final dash = await fetchDashboard();
          final accounts = dash['accounts'];
          if (accounts is List) return accounts;
        } catch (_) {}
      }
      throw Exception('Accounts endpoint failed (${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // parsed might be { data: [ ... ], paging: ... } OR the array itself
    if (parsed is Map && parsed.containsKey('data') && parsed['data'] is List) {
      return List<dynamic>.from(parsed['data'] as List);
    } else if (parsed is List) {
      return List<dynamic>.from(parsed);
    } else if (parsed is Map && parsed.containsKey('accounts') && parsed['accounts'] is List) {
      return List<dynamic>.from(parsed['accounts'] as List);
    }

    throw Exception('Invalid accounts payload');
  }

  // ---------------------------------------------------------------------------
  // 📊 METRICS (LAST 30 DAYS)
  // GET /api/mobile/instagram/{accountId}/metrics
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> fetchMetrics(int accountId) async {
    final uri = _uri('/api/mobile/instagram/$accountId/metrics');

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load metrics (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // parsed might be full wrapper or list
    if (parsed is Map && parsed.containsKey('data')) {
      final inner = parsed['data'];
      if (inner is List) return inner;
      if (inner == null) return [];
      if (inner is Map) return [inner];
    } else if (parsed is List) {
      return parsed;
    } else if (parsed == null) {
      return [];
    } else if (parsed is Map) {
      return [parsed];
    }

    throw Exception('Invalid metrics payload');
  }

  // ---------------------------------------------------------------------------
  // 📈 GRAPH (FULL HISTORY)
  // GET /api/mobile/instagram/{accountId}/graph
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> fetchGraph(int accountId) async {
    final uri = _uri('/api/mobile/instagram/$accountId/graph');

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load graph (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    if (parsed is Map && parsed.containsKey('data')) {
      final inner = parsed['data'];
      if (inner is List) return inner;
      if (inner == null) return [];
      if (inner is Map) return [inner];
    } else if (parsed is List) {
      return parsed;
    } else if (parsed == null) {
      return [];
    } else if (parsed is Map) {
      return [parsed];
    }

    throw Exception('Invalid graph payload');
  }

  // ---------------------------------------------------------------------------
  // 🔎 ACCOUNT DETAILS (profile, posts, metrics, graph, summary)
  // GET /api/mobile/instagram/{accountId}
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchAccountDetails(int accountId) async {
    final uri = _uri('/api/mobile/instagram/$accountId');

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load account details (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // parsed may be:
    //  - full wrapper Map (with keys: status, data, maybe paging)
    //  - inner data Map (instagram_account, profile, posts, metrics, graph, summary)
    if (parsed is Map && parsed.containsKey('data')) {
      final payload = parsed['data'];
      if (payload is Map) return _ensureMap(payload);
      throw Exception('Invalid account details payload (data not an object)');
    } else if (parsed is Map) {
      // already the inner object
      return _ensureMap(parsed);
    }

    throw Exception('Invalid account details payload');
  }

  // ---------------------------------------------------------------------------
  // 🔁 POSTS (paginated)
  // GET /api/mobile/instagram/{accountId}/posts?limit=12&after=<cursor>
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchPosts(int accountId, {int limit = 12, String? after}) async {
    final query = <String, dynamic>{'limit': limit};
    if (after != null) query['after'] = after;
    final uri = _uri('/api/mobile/instagram/$accountId/posts', query);

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load posts (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // Server often returns { status: true, data: [...], paging: {...} }
    if (parsed is Map) {
      // If parsed contains 'data' key, return as-is (data + paging)
      if (parsed.containsKey('data')) {
        final map = Map<String, dynamic>.from(parsed);
        // ensure data is list
        if (map['data'] is List) return map;
        // if data is a single object, wrap into list
        if (map['data'] is Map) {
          map['data'] = [map['data']];
          return map;
        }
        // if no data, return empty list
        map['data'] = <dynamic>[];
        return map;
      }

      // If parsed looks like the inner array or object, try to normalize:
      if (parsed.values.any((v) => v is List)) {
        return Map<String, dynamic>.from(parsed);
      }
    }

    if (parsed is List) {
      return {'data': parsed, 'paging': null};
    }

    throw Exception('Invalid posts payload');
  }

  // ---------------------------------------------------------------------------
  // 📌 POST INSIGHTS
  // GET /api/mobile/instagram/{accountId}/posts/{postId}/insights
  // returns either {insights: {...}, comments: [...], other: {...}} or wrapped under data
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchPostInsights(int accountId, String postId) async {
    final uri = _uri('/api/mobile/instagram/$accountId/posts/$postId/insights');

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load post insights (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // handle wrapper vs direct
    if (parsed is Map && parsed.containsKey('insights')) {
      // return the map as-is (UI normalizer will parse lists)
      return _ensureMap(parsed);
    } else if (parsed is Map && parsed.containsKey('data') && parsed['data'] is Map) {
      // return inner map
      return _ensureMap(parsed['data']);
    } else if (parsed is Map) {
      // sometimes parsed might be a map with keys 'insights','comments','other' nested in data already
      return _ensureMap(parsed);
    } else if (parsed is List) {
      // Graph-API style: a list of metrics -> let UI parse it
      return {'data': parsed};
    }

    throw Exception('Invalid post insights payload');
  }

  // ---------------------------------------------------------------------------
  // 💬 COMMENTS (paginated) - IMPROVED VERSION
  // GET /api/mobile/instagram/{accountId}/posts/{postId}/comments?limit=20&after=<cursor>
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchComments(int accountId, String postId, {int limit = 20, String? after}) async {
    final query = <String, dynamic>{'limit': limit};
    if (after != null && after.isNotEmpty) query['after'] = after;
    final uri = _uri('/api/mobile/instagram/$accountId/posts/$postId/comments', query);

    final res = await _http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to load comments (status ${res.statusCode})');
    }

    final parsed = await _parseJsonResponse(res);

    // We need to return a map with at least 'data' (list of comments) and optionally 'paging'.
    // The parsed response can be in various shapes. We'll normalize.

    // Case 1: parsed is a List -> treat as comments, no paging
    if (parsed is List) {
      return {'data': parsed, 'paging': null};
    }

    // Case 2: parsed is a Map
    if (parsed is Map) {
      // Try to find a list under common keys: 'data', 'comments', 'items'
      List<dynamic>? commentsList;

      // If there's a 'data' key and it's a List, use it
      if (parsed.containsKey('data') && parsed['data'] is List) {
        commentsList = parsed['data'] as List;
      }
      // Else if there's a 'comments' key and it's a List (maybe from insights endpoint)
      else if (parsed.containsKey('comments') && parsed['comments'] is List) {
        commentsList = parsed['comments'] as List;
      }
      // Else if there's a 'items' key and it's a List
      else if (parsed.containsKey('items') && parsed['items'] is List) {
        commentsList = parsed['items'] as List;
      }
      // Else if any value in the map is a List, assume that's the comments list
      else {
        final listValue = parsed.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (listValue != null) {
          commentsList = listValue as List;
        }
      }

      // If we found a comments list, construct the result
      if (commentsList != null) {
        final result = <String, dynamic>{'data': commentsList};

        // Preserve paging if present
        if (parsed.containsKey('paging')) {
          result['paging'] = parsed['paging'];
        } else if (parsed.containsKey('pagination')) {
          result['paging'] = parsed['pagination'];
        }

        return result;
      }

      // If we couldn't find a list, maybe the whole map is the comments data?
      // For example, if the API returns a single comment object? Unlikely, but handle gracefully.
      // We'll assume the map itself is the comment and wrap in list.
      return {'data': [parsed], 'paging': null};
    }

    // If we reach here, the response is neither List nor Map
    throw Exception('Invalid comments payload: unexpected type ${parsed.runtimeType}');
  }

  // =======================================================================
  // LIVE INSTAGRAM GRAPH API (optional)
  // These call the public Graph API using an IG access token (server token or page token)
  // =======================================================================

  // ---------------------------------------------------------------------------
  // Fetch live Instagram profile basic info (Graph API)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchLiveProfile({
    required String accessToken,
    String? igUserId,
    List<String>? fields,
    String graphVersion = 'v17.0',
  }) async {
    final chosenFields = (fields ?? ['username', 'followers_count', 'id', 'profile_picture_url']).join(',');

    final endpoint = (igUserId != null && igUserId.isNotEmpty)
        ? 'https://graph.facebook.com/$graphVersion/$igUserId'
        : 'https://graph.facebook.com/$graphVersion/me';

    final uri = Uri.parse('$endpoint?fields=$chosenFields&access_token=$accessToken');

    final res = await _http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch live profile (status ${res.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (e) {
      throw Exception('Invalid live profile JSON: $e');
    }
    if (decoded is! Map) {
      throw Exception('Unexpected live profile response shape');
    }
    return Map<String, dynamic>.from(decoded);
  }

  // ---------------------------------------------------------------------------
  // Fetch live Instagram insights (Graph API)
  // ---------------------------------------------------------------------------
  Future<List<dynamic>> fetchLiveInsights({
    required String accessToken,
    required String igUserId,
    List<String>? metrics,
    String period = 'day',
    int sinceDays = 30,
    String graphVersion = 'v17.0',
  }) async {
    final chosenMetrics = (metrics ?? ['impressions', 'reach', 'profile_views']).join(',');

    final now = DateTime.now().toUtc();
    final since = now.subtract(Duration(days: sinceDays));
    final sinceEpoch = since.millisecondsSinceEpoch ~/ 1000;
    final untilEpoch = now.millisecondsSinceEpoch ~/ 1000;

    final uri = Uri.parse(
      'https://graph.facebook.com/$graphVersion/$igUserId/insights'
      '?metric=$chosenMetrics'
      '&period=$period'
      '&since=$sinceEpoch'
      '&until=$untilEpoch'
      '&access_token=$accessToken',
    );

    final res = await _http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch live insights (status ${res.statusCode})');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (e) {
      throw Exception('Invalid live insights JSON: $e');
    }

    if (decoded is! Map || !decoded.containsKey('data')) {
      throw Exception('Unexpected live insights response shape');
    }

    return decoded['data'] as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Clean up (call on app dispose if you created the client)
  // ---------------------------------------------------------------------------
  void dispose() {
    try {
      _http.close();
    } catch (_) {}
  }
}