// lib/ui/screens/social_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/platform_provider.dart';
import '../widgets/platform_card.dart';
import '../../services/instagram_service.dart';

class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  final InstagramService _instagramService = InstagramService();

  bool _loadingAccounts = false;
  String? _error;
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    setState(() {
      _loadingAccounts = true;
      _error = null;
    });

    try {
      final accounts = await _instagramService.fetchAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loadingAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingAccounts = false;
      });

      // friendly user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Instagram accounts: ${e.toString()}')),
      );
    }
  }

  CurvedAnimation _stagger(int index, {double gap = 0.12}) {
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        (gap * index).clamp(0.0, 1.0),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlatformProvider>(context);
    final theme = AppColors.home;

    final platforms = [
      _PlatformEntry(
        id: 'instagram',
        title: 'Instagram',
        icon: Icons.camera_alt,
        theme: AppColors.instagram,
        description:
            "View reels, posts & insights from your connected Instagram account.",
        connected: provider.isConnected('instagram'),
      ),
      _PlatformEntry(
        id: 'facebook',
        title: 'Facebook',
        icon: Icons.facebook,
        theme: AppColors.facebook,
        description: "Facebook analytics are managed via the web dashboard.",
        connected: provider.isConnected('facebook'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        title: const Text("Social Hub", style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 6),
          Text(
            "Connected platforms (managed from web)",
            style: TextStyle(fontSize: 16, color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          ...List.generate(platforms.length, (i) {
            final item = platforms[i];
            final anim = _stagger(i);

            return AnimatedBuilder(
              animation: anim,
              builder: (context, child) {
                final t = anim.value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 12),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PlatformCard(
                  platform: item.id,
                  title: item.title,
                  icon: item.icon,
                  color: item.theme.badge,
                  description: item.description,
                  connected: item.connected,
                  readOnly: true, // 🔒 IMPORTANT
                  onToggle: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Connect or disconnect platforms from the web dashboard.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // -----------------------
          // Instagram accounts section
          // -----------------------
          if (_loadingAccounts) ...[
            const SizedBox(height: 6),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            _buildInstagramSection(provider),
          ],
        ]),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 1),
    );
  }

  Widget _buildInstagramSection(PlatformProvider provider) {
    // only show this section if the platform is connected (or if accounts exist)
    final isConnected = provider.isConnected('instagram') || _accounts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Instagram Accounts",
          style: TextStyle(fontSize: 16, color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (!isConnected) ...[
          Text(
            "No Instagram accounts connected. Connect from the web dashboard.",
            style: TextStyle(color: AppColors.textMedium),
          ),
        ] else if (_error != null) ...[
          Text(
            "Error: $_error",
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchAccounts,
            child: const Text('Retry'),
          ),
        ] else if (_accounts.isEmpty) ...[
          Text(
            "No accounts returned from server.",
            style: TextStyle(color: AppColors.textMedium),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final acc = _accounts[i];
              // defensive parsing
              Map<String, dynamic>? profile;
              if (acc['profile_data'] is Map) {
                profile = Map<String, dynamic>.from(acc['profile_data']);
              } else if (acc['profile_data'] is String) {
                try {
                  profile = (acc['profile_data'] as String).isNotEmpty
                      ? Map<String, dynamic>.from(
                          acc['profile_data'] is String
                              ? (acc['profile_data'] as String).startsWith('{')
                                  ? (acc['profile_data'] == '' ? {} : acc['profile_data'])
                                  : {}
                              : {}
                        )
                      : null;
                } catch (_) {
                  profile = null;
                }
              }

              final avatarUrl = profile != null
                  ? (profile['profile_picture_url'] ?? profile['profile_picture'] ?? null)
                  : null;

              final username = acc['username'] ?? acc['account_name'] ?? 'Unknown';
              final accountName = acc['account_name'] ?? '';
              final isPrimary = (acc['is_primary'] == 1 || acc['is_primary'] == true);

              return Card(
                color: Colors.white,
                child: ListTile(
                  leading: avatarUrl != null && avatarUrl is String && avatarUrl.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                        )
                      : CircleAvatar(
                          backgroundColor: AppColors.instagram.badge,
                          child: const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                  title: Text(username, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: accountName.isNotEmpty ? Text(accountName) : null,
                  trailing: isPrimary
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text('Primary', style: TextStyle(color: AppColors.primary)),
                            ],
                          ),
                        )
                      : null,
                  onTap: () {
                    // Example: navigate to Instagram account detail / metrics screen
                    Navigator.pushNamed(context, '/instagram-account', arguments: acc['id']);
                  },
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SUPPORT CLASSES
// ---------------------------------------------------------------------------
class _PlatformEntry {
  final String id;
  final String title;
  final IconData icon;
  final PageTheme theme;
  final String description;
  final bool connected;

  _PlatformEntry({
    required this.id,
    required this.title,
    required this.icon,
    required this.theme,
    required this.description,
    required this.connected,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      elevation: 12,
      onTap: (i) {
        const routes = [
          "/home",
          "/social-hub",
          "/dashboard",
          "/insights",
          "/settings",
        ];
        Navigator.pushReplacementNamed(context, routes[i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: "Social Hub"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Insights"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}
