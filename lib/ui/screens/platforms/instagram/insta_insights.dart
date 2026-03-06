// lib/ui/screens/platforms/instagram/insta_insights.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/selected_account_provider.dart';
import '../../../../services/instagram_service.dart';

class InstaInsights extends StatefulWidget {
  const InstaInsights({super.key});

  @override
  State<InstaInsights> createState() => _InstaInsightsState();
}

class _InstaInsightsState extends State<InstaInsights> {
  late final InstagramService _instagramService;
  final ScrollController _scrollController = ScrollController();
  final DateFormat _fmt = DateFormat.yMMMd().add_Hm();

  // Data
  Map<String, dynamic>? _profile;
  final List<Map<String, dynamic>> _posts = [];
  String? _nextCursor;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  Map<String, dynamic>? _lastAccount;

  @override
  void initState() {
    super.initState();
    _instagramService = InstagramService();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _instagramService.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _nextCursor == null) return;
    final threshold = 300.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      _loadMorePosts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = context.watch<SelectedAccountProvider>().selectedAccount;
    if (account != _lastAccount) {
      _lastAccount = account;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadAccountDetails(account);
      });
    }
  }

  Future<void> _loadAccountDetails(Map<String, dynamic>? account) async {
    setState(() {
      _loading = true;
      _error = null;
      _posts.clear();
      _profile = null;
      _nextCursor = null;
    });

    if (account == null) {
      setState(() {
        _loading = false;
        _error = 'No Instagram account selected';
      });
      return;
    }

    final accountId = account['id'];
    if (accountId == null) {
      setState(() {
        _loading = false;
        _error = 'Invalid account data (missing id)';
      });
      return;
    }

    try {
      final details = await _instagramService.fetchAccountDetails(accountId);
      if (!mounted) return;

      final profileData = details['profile'] as Map<String, dynamic>? ?? {};
      final initialPosts = details['posts'] as List<dynamic>? ?? [];

      setState(() {
        _profile = profileData;
        _posts.addAll(
          initialPosts.map((p) => Map<String, dynamic>.from(p)).toList(),
        );
        _loading = false;
      });

      _checkForMorePosts(accountId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _checkForMorePosts(int accountId) async {
    try {
      final result = await _instagramService.fetchPosts(
        accountId,
        limit: 1,
        after: null,
      );
      if (!mounted) return;

      final paging = result['paging'] as Map<String, dynamic>?;
      final cursors = paging?['cursors'] as Map<String, dynamic>?;
      final next = cursors?['after'] as String?;
      setState(() {
        _nextCursor = next;
      });
    } catch (e) {
      // fail silently
    }
  }

  Future<void> _loadMorePosts() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);

    final account = context.read<SelectedAccountProvider>().selectedAccount;
    final accountId = account?['id'];
    if (accountId == null) {
      setState(() {
        _loadingMore = false;
        _error = 'Account id missing';
      });
      return;
    }

    try {
      final result = await _instagramService.fetchPosts(
        accountId,
        limit: 12,
        after: _nextCursor,
      );
      if (!mounted) return;

      final newPosts = result['data'] as List<dynamic>? ?? [];
      final paging = result['paging'] as Map<String, dynamic>?;
      final cursors = paging?['cursors'] as Map<String, dynamic>?;
      final next = cursors?['after'] as String?;

      setState(() {
        _posts.addAll(
          newPosts.map((p) => Map<String, dynamic>.from(p)).toList(),
        );
        _nextCursor = next;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = 'Failed to load more posts: $e';
        _nextCursor = null;
      });
    }
  }

  Future<void> _refresh() async {
    final account = context.read<SelectedAccountProvider>().selectedAccount;
    await _loadAccountDetails(account);
  }

  void _openPostDialog(BuildContext ctx, Map<String, dynamic> post) {
    final accountId = context.read<SelectedAccountProvider>().selectedAccount?['id'];
    if (accountId == null) return;

    showDialog(
      context: ctx,
      builder: (_) => PostDetailDialog(
        accountId: accountId,
        post: post,
        instagramService: _instagramService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<SelectedAccountProvider>().selectedAccount;
    if (account == null) {
      return const Center(child: Text('No Instagram account selected on Dashboard.'));
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _headerRow()),
          if (_posts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No posts found. Pull to refresh.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _posts.length) return null;
                    final item = _posts[index];
                    final mediaType =
                        (item['media_type'] ?? '').toString().toUpperCase();
                    final imageUrl = mediaType == 'VIDEO'
                        ? (item['thumbnail_url'] ?? item['media_url'])
                        : (item['media_url'] ?? item['thumbnail_url']);
                    final ts = item['timestamp']?.toString();
                    return GestureDetector(
                      onTap: () => _openPostDialog(context, item),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        color: Colors.grey.shade200,
                        child: Stack(
                          children: [
                            if (imageUrl != null)
                              Positioned.fill(
                                child: Image.network(
                                  imageUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(child: Icon(Icons.broken_image)),
                                ),
                              )
                            else
                              const Center(child: Icon(Icons.image, size: 36)),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ts != null ? _safeFormat(ts) : '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                            if (mediaType == 'VIDEO')
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _posts.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : (_nextCursor != null
                        ? ElevatedButton(
                            onPressed: _loadMorePosts,
                            child: const Text('Load more'),
                          )
                        : const Text('No more posts')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: (_profile != null &&
                    (_profile!['profile_picture_url'] ?? _profile!['picture']) != null)
                ? NetworkImage(
                    (_profile!['profile_picture_url'] ?? _profile!['picture']).toString(),
                  )
                : null,
            child: (_profile == null ||
                    (_profile!['profile_picture_url'] ?? _profile!['picture']) == null)
                ? const Icon(Icons.camera_alt)
                : null,
          ),
          const SizedBox(width: 12),
          if (_profile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!['username'] ?? 'Instagram',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'User ID: ${_profile!['id'] ?? '—'}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          const Spacer(),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  static String _safeFormat(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }
}

/// Dialog for single post details + insights + comments
class PostDetailDialog extends StatefulWidget {
  final int accountId;
  final Map<String, dynamic> post;
  final InstagramService instagramService;

  const PostDetailDialog({
    super.key,
    required this.accountId,
    required this.post,
    required this.instagramService,
  });

  @override
  State<PostDetailDialog> createState() => _PostDetailDialogState();
}

class _PostDetailDialogState extends State<PostDetailDialog> {
  Map<String, dynamic>? _insights;
  List<dynamic>? _comments;
  String? _insightError;
  String? _commentsError;
  bool _loadingInsights = false;
  bool _loadingComments = false;

  @override
  void initState() {
    super.initState();
    _loadInsightsAndComments();
  }

  Future<void> _loadInsightsAndComments() async {
    await _loadInsights();
    await _loadComments();
  }

  Future<void> _loadInsights() async {
    final postId = widget.post['id']?.toString();
    if (postId == null) {
      setState(() {
        _insightError = 'Post id missing';
      });
      return;
    }

    setState(() {
      _loadingInsights = true;
      _insightError = null;
    });

    try {
      final result = await widget.instagramService.fetchPostInsights(
        widget.accountId,
        postId,
      );
      if (!mounted) return;

      setState(() {
        _insights = result['insights'] as Map<String, dynamic>?;
        _loadingInsights = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _insightError = e.toString();
        _loadingInsights = false;
      });
    }
  }

  Future<void> _loadComments() async {
    final postId = widget.post['id']?.toString();
    if (postId == null) {
      setState(() {
        _commentsError = 'Post id missing';
      });
      return;
    }

    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });

    try {
      // Fetch up to 50 comments (you can adjust the limit)
      final result = await widget.instagramService.fetchComments(
        widget.accountId,
        postId,
        limit: 50,
      );
      if (!mounted) return;

      setState(() {
        _comments = result['data'] as List<dynamic>? ?? [];
        _loadingComments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError = e.toString();
        _loadingComments = false;
      });
    }
  }

  Future<void> _openPermalink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open link')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Widget> _renderMetrics(Map<String, dynamic> insights) {
    final list = <Widget>[];
    insights.forEach((key, value) {
      list.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(key.toString()),
              Text(value?.toString() ?? '-'),
            ],
          ),
        ),
      );
    });
    return list;
  }

  Widget _buildComment(dynamic comment) {
    final Map<String, dynamic> c = comment is Map ? Map.from(comment) : {};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['username'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(c['text'] ?? ''),
              ],
            ),
          ),
          if (c['like_count'] != null)
            Row(
              children: [
                const Icon(Icons.favorite, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(c['like_count'].toString()),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final mediaType = (p['media_type'] ?? '').toString().toUpperCase();
    final imageUrl = mediaType == 'VIDEO'
        ? p['thumbnail_url'] ?? p['media_url']
        : p['media_url'] ?? p['thumbnail_url'];
    final caption = (p['caption'] ?? '').toString();
    final permalink = p['permalink']?.toString();

    return AlertDialog(
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: imageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                          if (mediaType == 'VIDEO')
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 48,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      )
                    : const ColoredBox(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (caption.isNotEmpty) Text(caption),
              const SizedBox(height: 6),
              Text(
                'Posted: ${p['timestamp'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (permalink != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        permalink,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openPermalink(permalink),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              const Divider(),
              // Insights Section
              if (_loadingInsights)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_insights != null && _insights!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metrics',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._renderMetrics(_insights!),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metrics',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _insightError ??
                          'Insights not available for this post.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              // Comments Section
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_loadingComments)
                const Center(child: CircularProgressIndicator())
              else if (_commentsError != null)
                Text(
                  _commentsError!,
                  style: const TextStyle(color: Colors.red),
                )
              else if (_comments != null && _comments!.isNotEmpty)
                ..._comments!.map((c) => _buildComment(c)).toList()
              else
                const Text('No comments yet.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}