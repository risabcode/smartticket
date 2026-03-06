// lib/ui/screens/platforms/instagram/insta_dashboard_compact_responsive.dart
import 'dart:convert';
import 'dart:math';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../services/instagram_service.dart';
import '../../../../providers/user_provider.dart';
import '../../../../providers/selected_account_provider.dart';

/// Enhanced mobile-first, clean and compact responsive Instagram dashboard.
/// Improvements:
/// - Better chart handling (single point, zero values, axis formatting)
/// - Responsive layout using LayoutBuilder for adaptive columns
/// - Improved error states and loading indicators
/// - Richer insights dialog with comment details
/// - Visual polish (colors, spacing, shadows)
/// - Added two new graphs: net followers change & posts per day
class InstaDashboardCompact extends StatefulWidget {
  const InstaDashboardCompact({Key? key}) : super(key: key);

  @override
  State<InstaDashboardCompact> createState() => _InstaDashboardCompactState();
}

class _InstaDashboardCompactState extends State<InstaDashboardCompact> {
  final InstagramService _service = InstagramService();
  final DateFormat _pretty = DateFormat('yMMMd');
  final DateFormat _chartDate = DateFormat('MM/dd');

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _accounts = [];
  Map<String, dynamic>? _selectedAccount;

  Map<String, dynamic> _profile = {};
  List<dynamic> _metrics = []; // descending (latest first)
  List<dynamic> _graph = []; // series with snapshot_date + followers/impressions/etc

  List<Map<String, dynamic>> _posts = [];
  String? _cursor;
  bool _hasMore = true;

  // aggregates used by UI
  int _aggLikes = 0;
  int _aggComments = 0;
  int _aggViews = 0;
  int _aggImpressions = 0;
  int _aggReach = 0;
  int _aggInteractions = 0;
  Map<String, int> _typeCounts = {};

  // insights modal
  bool _insLoading = false;
  Map<String, dynamic>? _insights;
  List<dynamic> _insComments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userProv = Provider.of<UserProvider>(context, listen: false);
    if (!userProv.isLoggedIn) {
      setState(() {
        _loading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    try {
      Map<String, dynamic>? dash;
      try {
        dash = await _service.fetchDashboard();
      } catch (_) {
        dash = null;
      }

      List<dynamic> accountsRaw = [];
      if (dash != null && dash['accounts'] is List) {
        accountsRaw = dash['accounts'] as List;
      } else {
        accountsRaw = await _service.fetchAccounts();
      }

      _accounts = accountsRaw.map<Map<String, dynamic>>((a) {
        if (a is Map<String, dynamic>) return a;
        if (a is Map) return Map<String, dynamic>.from(a);
        try {
          return Map<String, dynamic>.from(jsonDecode(a.toString()));
        } catch (_) {
          return <String, dynamic>{};
        }
      }).where((m) => m.isNotEmpty).toList();

      _selectedAccount = _accounts.isNotEmpty ? _accounts.first : null;

      if (_selectedAccount != null) {
        final id = int.tryParse(_selectedAccount!['id']?.toString() ?? '0') ?? 0;
        await _loadAccount(id, replace: true, dashboardCache: dash);
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadAccount(int accountId,
      {bool replace = false, Map<String, dynamic>? dashboardCache}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> details = {};
      // try dashboard cache first
      if (dashboardCache != null && dashboardCache['accounts'] is List) {
        final found = (dashboardCache['accounts'] as List).cast().firstWhere(
            (a) => (a is Map && (a['id']?.toString() == accountId.toString())),
            orElse: () => null);
        if (found != null && found is Map) {
          details = Map<String, dynamic>.from(found);
          details['posts'] = details['posts'] ?? [];
          details['metrics'] = details['recent_metrics'] ?? details['metrics'] ?? [];
        }
      }

      if (details.isEmpty) {
        try {
          final resp = await _service.fetchAccountDetails(accountId);
          if (resp.containsKey('instagram_account') || resp.containsKey('profile')) {
            details = Map<String, dynamic>.from(resp);
          } else if (resp.containsKey('data') && resp['data'] is Map) {
            details = Map<String, dynamic>.from(resp['data']);
          } else {
            details = Map<String, dynamic>.from(resp);
          }
        } catch (e) {
          final metrics = await _service.fetchMetrics(accountId);
          details = {'profile': null, 'metrics': metrics ?? [], 'posts': []};
        }
      }

      _profile = _normalizeProfile(details['profile'] ?? _selectedAccount);
      _metrics = (details['metrics'] is List) ? List<dynamic>.from(details['metrics']) : <dynamic>[];

      try {
        final g = await _service.fetchGraph(accountId);
        _graph = (g is List) ? g : _metrics;
      } catch (_) {
        _graph = _metrics;
      }

      final postsRaw = (details['posts'] is List) ? List<dynamic>.from(details['posts']) : <dynamic>[];
      if (replace) {
        _posts = postsRaw.whereType<Map<String, dynamic>>().map((p) => Map<String, dynamic>.from(p)).toList();
        _cursor = _posts.isNotEmpty ? _posts.last['id']?.toString() : null;
        _hasMore = _posts.isNotEmpty;
      }

      _computeAggregates();

      final selProv = Provider.of<SelectedAccountProvider>(context, listen: false);
      selProv.setSelectedAccount(_selectedAccount);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _computeAggregates() {
    int likes = 0;
    int comments = 0;
    int views = 0;
    int impressions = 0;
    int reach = 0;
    int interactions = 0;
    final Map<String, int> types = {};

    for (final p in _posts) {
      final like = (p['like_count'] ?? p['likes'] ?? 0) as int;
      final comm = (p['comments_count'] ?? p['comments'] ?? 0) as int;
      final vw = (p['video_views'] ?? p['views'] ?? p['views_count'] ?? 0) as int;
      final impr = (p['impressions'] ?? p['views'] ?? 0) as int;
      final r = (p['reach'] ?? 0) as int;
      final inter = (p['total_interactions'] ?? ((p['like_count'] ?? 0) + (p['comments_count'] ?? 0) + (p['saved'] ?? 0))) as int;

      likes += like;
      comments += comm;
      views += vw;
      impressions += impr;
      reach += r;
      interactions += inter;

      final mt = (p['media_type'] ?? p['type'] ?? 'UNKNOWN').toString().toUpperCase();
      types[mt] = (types[mt] ?? 0) + 1;
    }

    _aggLikes = likes;
    _aggComments = comments;
    _aggViews = views;
    _aggImpressions = impressions;
    _aggReach = reach;
    _aggInteractions = interactions;
    _typeCounts = types;
  }

  Map<String, dynamic> _normalizeProfile(dynamic src) {
    if (src == null) return {};
    if (src is Map<String, dynamic>) {
      if (src.containsKey('profile_data') && src['profile_data'] is Map) {
        return Map<String, dynamic>.from(src['profile_data']);
      }
      return Map<String, dynamic>.from(src);
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(src.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _loadMorePosts({int limit = 12}) async {
    if (!_hasMore) return;
    final id = int.tryParse(_selectedAccount?['id']?.toString() ?? '0') ?? 0;
    if (id == 0) return;

    try {
      final res = await _service.fetchPosts(id, limit: limit, after: _cursor);
      if (res is Map<String, dynamic>) {
        final data = res['data'];
        final paging = res['paging'];
        if (data is List) {
          final newPosts = data.whereType<Map<String, dynamic>>().map((p) => Map<String, dynamic>.from(p)).toList();
          setState(() {
            _posts.addAll(newPosts);
            _cursor = paging != null && paging['cursors'] != null ? paging['cursors']['after'] : null;
            _hasMore = _cursor != null;
            _computeAggregates();
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load more posts: ${e.toString()}')));
    }
  }

  Future<void> _openInsights(String postId) async {
    setState(() {
      _insLoading = true;
      _insights = null;
      _insComments = [];
    });

    try {
      final accountId = int.tryParse(_selectedAccount?['id']?.toString() ?? '0') ?? 0;
      final res = await _service.fetchPostInsights(accountId, postId);
      setState(() {
        if (res.containsKey('insights')) {
          _insights = Map<String, dynamic>.from(res['insights'] ?? {});
          _insComments = res['comments'] is List ? List<dynamic>.from(res['comments']) : [];
        } else if (res.containsKey('data') && res['data'] is Map) {
          final d = res['data'] as Map;
          _insights = Map<String, dynamic>.from(d['insights'] ?? {});
          _insComments = d['comments'] is List ? List<dynamic>.from(d['comments']) : [];
        } else {
          _insights = Map<String, dynamic>.from(res);
        }
        _insLoading = false;
      });

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _InsightsSheet(insights: _insights, comments: _insComments),
      );
    } catch (e) {
      setState(() {
        _insLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load insights: ${e.toString()}')));
    }
  }

  // --- New methods for additional charts ---

  /// Computes daily net follower change from _graph data.
  /// Returns list of net changes aligned with _graph indices (first value is 0).
  List<double> _dailyNetFollowers() {
    if (_graph.isEmpty) return [];
    final followersSeries = _seriesForKey('followers');
    if (followersSeries.length < 2) return List.filled(followersSeries.length, 0.0);

    final net = <double>[];
    net.add(0.0); // first day no change
    for (int i = 1; i < followersSeries.length; i++) {
      net.add(followersSeries[i] - followersSeries[i - 1]);
    }
    return net;
  }

  /// Groups posts by date (day) and returns a sorted list of (date, count)
  /// for the period covered by _graph dates (or last 30 days if _graph empty).
  List<MapEntry<DateTime, int>> _postCountsPerDay() {
    if (_posts.isEmpty) return [];

    // Determine date range: use _graph dates if available, otherwise last 30 days from now
    DateTime start, end;
    if (_graph.isNotEmpty && _dates.isNotEmpty && _dates.first.millisecondsSinceEpoch != 0) {
      start = _dates.last; // oldest (since _graph is descending? need check)
      end = _dates.first;   // newest
      // Ensure start <= end
      if (start.isAfter(end)) {
        final temp = start;
        start = end;
        end = temp;
      }
    } else {
      end = DateTime.now();
      start = end.subtract(const Duration(days: 30));
    }

    // Generate all days in range
    final days = <DateTime>[];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      days.add(start.add(Duration(days: i)));
    }

    // Count posts per day
    final counts = <DateTime, int>{};
    for (final day in days) {
      counts[day] = 0;
    }

    for (final post in _posts) {
      final timestamp = post['timestamp'] ?? post['created_time'] ?? post['snapshot_date'];
      if (timestamp == null) continue;
      final date = DateTime.tryParse(timestamp.toString());
      if (date == null) continue;
      // Normalize to day
      final day = DateTime(date.year, date.month, date.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      counts[day] = (counts[day] ?? 0) + 1;
    }

    // Sort by date
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  // --- existing helpers ---

  List<double> _seriesForKey(String key) {
    final alt = {
      'followers': ['followers', 'followers_count'],
      'impressions': ['impressions'],
      'reach': ['reach'],
    }[key] ??
        [key];

    return _graph.map<double>((g) {
      if (g is Map) {
        for (final k in alt) {
          if (g.containsKey(k)) {
            final v = g[k];
            if (v == null) return 0.0;
            if (v is num) return v.toDouble();
            return double.tryParse(v.toString()) ?? 0.0;
          }
        }
      }
      return 0.0;
    }).toList();
  }

  List<DateTime> get _dates => _graph
      .map((g) => g is Map
          ? (DateTime.tryParse(g['snapshot_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0))
      .toList();

  String _num(dynamic v) {
    if (v == null) return '—';
    if (v is num) return NumberFormat.compact().format(v);
    final n = num.tryParse(v.toString());
    return n != null ? NumberFormat.compact().format(n) : v.toString();
  }

  double _engagementRate() {
    final followers = (_profile['followers_count'] ?? _profile['followers'] ?? 0);
    if (followers is num && followers > 0) {
      return (_aggInteractions / (followers as num)) * 100;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_selectedAccount == null) return const Center(child: Text('No Instagram account connected.'));

    final followersSeries = _seriesForKey('followers');
    final impressionsSeries = _seriesForKey('impressions');
    final netFollowers = _dailyNetFollowers();
    final postCounts = _postCountsPerDay();

    final followersLatest = _metrics.isNotEmpty ? (_metrics.first['followers'] ?? _metrics.first['followers_count'] ?? 0) : 0;

    return RefreshIndicator(
      onRefresh: () async {
        final id = int.tryParse(_selectedAccount!['id']?.toString() ?? '0') ?? 0;
        await _loadAccount(id, replace: true);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Account selector + actions
              Row(children: [
                Expanded(child: _accountDropdown()),
                const SizedBox(width: 8),
                IconButton(onPressed: () async => await _bootstrap(), icon: const Icon(Icons.refresh)),
                IconButton(onPressed: () async {
                  final id = int.tryParse(_selectedAccount?['id']?.toString() ?? '0') ?? 0;
                  if (id == 0) return;
                  await _loadAccount(id, replace: true);
                }, icon: const Icon(Icons.sync)),
              ]),

              const SizedBox(height: 12),

              // 1) Profile card
              _ProfileCardColored(profile: _profile, account: _selectedAccount!),

              const SizedBox(height: 12),

              // 2) Community section (existing graph)
              _SectionCard(
                title: 'Community — Last 30 days',
                child: Column(children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: _SimpleLineChart(
                      data: followersSeries,
                      dates: _dates,
                      showLeftAxis: true,
                      showBottomDots: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Followers: ${_num(followersLatest)}'),
                    Text('Period: 30d')
                  ])
                ]),
              ),

              const SizedBox(height: 12),

              // 3) Balance of Followers (new graph + stats)
              _SectionCard(
                title: 'Balance of Followers',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  Text('Daily net follower change', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _NetFollowersChart(data: netFollowers, dates: _dates),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _coloredStat('Net', _formatSigned(_computeNetFollowers()), color: Colors.purple),
                      _coloredStat('New', _num(_computeNewFollowers()), color: Colors.green),
                      _coloredStat('Lost', _num(_computeLostFollowers()), color: Colors.red),
                    ],
                  )
                ]),
              ),

              const SizedBox(height: 12),

              // 4) Posts published in period (new graph + stats)
              _SectionCard(
                title: 'Posts published in period',
                child: Column(children: [
                  const SizedBox(height: 8),
                  Text('Daily post count', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: _PostsPerDayChart(data: postCounts),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _statTile('Engagement', '${_engagementRate().toStringAsFixed(1)}%'),
                    _statTile('Interactions', _num(_aggInteractions)),
                    _statTile('Avg reach / post', _num(_avgReachPerPost())),
                    _statTile('Views', _num(_aggViews)),
                    _statTile('Posts', _posts.length.toString()),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Types', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Count', style: const TextStyle(fontWeight: FontWeight.bold))
                  ]),
                  const SizedBox(height: 8),
                  ..._typeCounts.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(e.key),
                      Text(e.value.toString())
                    ]),
                  )).toList(),
                ]),
              ),

              const SizedBox(height: 12),

              // 5) Views / Posts summary (unchanged)
              _SectionCard(
                title: 'Overview',
                child: Column(children: [
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _overviewStat('Views', _num(_aggViews)),
                      _overviewStat('Posts', _posts.length.toString()),
                      _overviewStat('Interactions', _num(_aggInteractions)),
                      _overviewStat('Avg reach/post', _num(_avgReachPerPost())),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              // 6) Posts list (unchanged)
              const Text('Recent posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _PostsListCompact(
                posts: _posts,
                onShowInsights: _openInsights,
                onLoadMore: _loadMorePosts,
                hasMore: _hasMore,
              ),

              const SizedBox(height: 80),
            ]),
          );
        },
      ),
    );
  }

  // calc helpers (unchanged)
  int _computeNetFollowers() {
    if (_graph.isEmpty) return 0;
    final first = _graph.lastWhere((g) => g is Map && (g['followers'] ?? g['followers_count']) != null, orElse: () => null);
    final last = _graph.firstWhere((g) => g is Map && (g['followers'] ?? g['followers_count']) != null, orElse: () => null);
    if (first == null || last == null) return 0;
    final f = (first['followers'] ?? first['followers_count'] ?? 0) as num;
    final l = (last['followers'] ?? last['followers_count'] ?? 0) as num;
    return (l - f).toInt();
  }

  int _computeNewFollowers() {
    final net = _computeNetFollowers();
    return net > 0 ? net : 0;
  }

  int _computeLostFollowers() {
    final net = _computeNetFollowers();
    return net < 0 ? -net : 0;
  }

  num _avgReachPerPost() {
    if (_posts.isEmpty) return 0;
    return _aggReach / _posts.length;
  }

  String _formatSigned(int v) => v > 0 ? '+$v' : v.toString();

  Widget _accountDropdown() { /* unchanged */ 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [
        const Icon(Icons.account_circle, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedAccount,
              items: _accounts.map((a) {
                final label = a['username'] ?? a['account_name'] ?? 'Account';
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: a,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _selectedAccount = v);
                final id = int.tryParse(v['id']?.toString() ?? '0') ?? 0;
                final selProv = Provider.of<SelectedAccountProvider>(context, listen: false);
                selProv.setSelectedAccount(v);
                await _loadAccount(id, replace: true);
              },
            ),
          ),
        )
      ]),
    );
  }

  Widget _coloredStat(String label, String value, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.9), fontSize: 12)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _statTile(String title, String value) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _overviewStat(String label, String value) => Column(children: [
    Text(label, style: const TextStyle(color: Colors.black54)),
    const SizedBox(height: 8),
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
  ]);
}

// ---------- Reusable widgets (enhanced with two new charts) ----------

class _SectionCard extends StatelessWidget { /* unchanged */ 
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }
}

class _ProfileCardColored extends StatelessWidget { /* unchanged */ 
  final Map<String, dynamic> profile;
  final Map<String, dynamic> account;
  const _ProfileCardColored({required this.profile, required this.account});

  String _num(dynamic v) {
    if (v == null) return '—';
    if (v is num) return NumberFormat.compact().format(v);
    final n = num.tryParse(v.toString());
    return n != null ? NumberFormat.compact().format(n) : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final username = profile['username'] ?? account['username'] ?? 'Instagram';
    final name = profile['name'] ?? account['account_name'] ?? '';
    final picture = profile['profile_picture_url'];
    final followers = profile['followers_count'] ?? profile['followers'] ?? 0;
    final following = profile['follows_count'] ?? profile['following'] ?? 0;
    final media = profile['media_count'] ?? profile['media'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 36,
          backgroundImage: (picture != null && picture is String) ? NetworkImage(picture) : null,
          backgroundColor: Colors.grey.shade100,
          child: picture == null ? const Icon(Icons.camera_alt) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if ((name ?? '').toString().isNotEmpty)
              Text(name, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('Followers', _num(followers), color: Colors.indigo),
                _metricChip('Following', _num(following), color: Colors.orange),
                _metricChip('Posts', _num(media), color: Colors.green),
              ],
            )
          ]),
        )
      ]),
    );
  }

  Widget _metricChip(String label, String value, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

/// Enhanced line chart (unchanged)
class _SimpleLineChart extends StatelessWidget {
  final List<double> data;
  final List<DateTime> dates;
  final bool showLeftAxis;
  final bool showBottomDots;

  const _SimpleLineChart({
    required this.data,
    required this.dates,
    this.showLeftAxis = true,
    this.showBottomDots = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((d) => d == 0)) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final spots = List<FlSpot>.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    
    double minY = spots.map((p) => p.y).reduce(min);
    double maxY = spots.map((p) => p.y).reduce(max);
    
    if (minY == maxY) {
      if (minY == 0) {
        minY = -1;
        maxY = 1;
      } else {
        minY = minY * 0.9;
        maxY = maxY * 1.1;
      }
    } else {
      final padding = (maxY - minY) * 0.1;
      minY = max(0, minY - padding);
      maxY = maxY + padding;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(
              show: showBottomDots,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: Colors.indigo,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            barWidth: 3,
            color: Colors.indigo,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.withOpacity(0.1),
            ),
          )
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showLeftAxis,
              interval: (maxY - minY) / 4,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact().format(value),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: dates.isNotEmpty && dates.length > 1,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(dates[index]),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_formatNumber(spot.y)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

/// New chart for net followers change (line chart with zero baseline)
class _NetFollowersChart extends StatelessWidget {
  final List<double> data;
  final List<DateTime> dates;

  const _NetFollowersChart({required this.data, required this.dates});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((d) => d == 0)) {
      return Center(
        child: Text(
          'No change data',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final spots = List<FlSpot>.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    
    // Find min and max including zero for baseline
    double minY = spots.map((p) => p.y).reduce(min);
    double maxY = spots.map((p) => p.y).reduce(max);
    // Ensure zero is within range
    if (minY > 0) minY = 0;
    if (maxY < 0) maxY = 0;
    // Add small padding
    final range = maxY - minY;
    if (range == 0) {
      minY = -1;
      maxY = 1;
    } else {
      minY = minY - range * 0.1;
      maxY = maxY + range * 0.1;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
            barWidth: 2,
            color: Colors.purple,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.1),
            ),
          )
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) / 4,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: dates.isNotEmpty && dates.length > 1,
              interval: max(1, (dates.length / 4).floor()).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(dates[index]),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final value = spot.y;
                return LineTooltipItem(
                  value > 0 ? '+${value.toInt()}' : value.toInt().toString(),
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// New chart for posts per day (bar chart)
class _PostsPerDayChart extends StatelessWidget {
  final List<MapEntry<DateTime, int>> data;

  const _PostsPerDayChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((e) => e.value == 0)) {
      return Center(
        child: Text(
          'No posts in period',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i].value.toDouble(),
              color: Colors.green,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )
          ],
        ),
      );
    }

    double maxY = data.map((e) => e.value.toDouble()).reduce(max);
    if (maxY == 0) maxY = 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + 1,
        barGroups: bars,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: data.length > 1,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(data[index].key),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} posts',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PostsListCompact extends StatelessWidget { /* unchanged */ 
  final List<Map<String, dynamic>> posts;
  final Future<void> Function(String postId) onShowInsights;
  final Future<void> Function({int limit}) onLoadMore;
  final bool hasMore;

  const _PostsListCompact({
    required this.posts,
    required this.onShowInsights,
    required this.onLoadMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No posts found.')),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, idx) {
              final p = posts[idx];
              final thumb = p['thumbnail_url'] ?? p['media_url'] ?? '';
              final caption = (p['caption'] ?? '').toString();
              final reach = p['reach'] ?? p['impressions'] ?? p['views'] ?? 0;
              final views = p['video_views'] ?? p['views'] ?? 0;
              final interactions = p['total_interactions'] ?? ((p['like_count'] ?? 0) + (p['comments_count'] ?? 0));
              final mediaId = p['id']?.toString() ?? '';

              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumb,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _tinyStat('Reach', _formatNumber(reach)),
                        _tinyStat('Views', _formatNumber(views)),
                        _tinyStat('Int.', _formatNumber(interactions)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(
                        _formatDate(p['timestamp'] ?? p['created_time'] ?? p['snapshot_date']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => onShowInsights(mediaId),
                        style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                        child: const Text('Insights'),
                      ),
                    ])
                  ]),
                )
              ]);
            },
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: ElevatedButton(
                  onPressed: () => onLoadMore(limit: 12),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Load more'),
                ),
              ),
            )
        ]),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '—';
    final num v = (value is num) ? value : (num.tryParse(value.toString()) ?? 0);
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toString();
  }

  Widget _tinyStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    try {
      final dt = DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (dt.millisecondsSinceEpoch == 0) return '';
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      return v.toString();
    }
  }
}

/// Bottom sheet for post insights (unchanged)
class _InsightsSheet extends StatelessWidget {
  final Map<String, dynamic>? insights;
  final List<dynamic> comments;
  const _InsightsSheet({this.insights, required this.comments});

  @override
  Widget build(BuildContext context) {
    final ins = insights ?? {};
    final impressions = ins['impressions'] ?? ins['views'] ?? ins['views_count'] ?? 0;
    final reach = ins['reach'] ?? 0;
    final engagement = ins['engagement'] ?? ins['total_interactions'] ?? 0;
    final caption = (ins['caption'] ?? ins['other']?['caption'] ?? 'No caption').toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Post Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _insightMetric('Impressions', _formatNumber(impressions)),
                    _insightMetric('Reach', _formatNumber(reach)),
                    _insightMetric('Engagement', _formatNumber(engagement)),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Caption', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(caption),
                  const SizedBox(height: 20),
                  const Text('Top comments', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (comments.isEmpty)
                    const Text('No comments available', style: TextStyle(color: Colors.grey))
                  else
                    ...comments.take(5).map((c) {
                      final cm = c is Map ? c : {};
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: cm['profile_picture'] != null
                              ? NetworkImage(cm['profile_picture'].toString())
                              : null,
                          child: cm['profile_picture'] == null ? const Icon(Icons.person, size: 16) : null,
                        ),
                        title: Text(cm['username'] ?? 'user', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(cm['text'] ?? cm['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Text((cm['like_count'] ?? 0).toString()),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '—';
    final num v = (value is num) ? value : (num.tryParse(value.toString()) ?? 0);
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toString();
  }

  Widget _insightMetric(String label, String value) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }
}