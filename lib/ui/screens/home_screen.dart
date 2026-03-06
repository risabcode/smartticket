// lib/ui/screens/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../services/instagram_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InstagramService _service = InstagramService();
  final DateFormat _df = DateFormat.yMMMd().add_jm();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _brand;
  Map<String, dynamic>? _manager;
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.fetchDashboard();
      setState(() {
        _user = (res['mobile_user'] is Map) ? Map<String, dynamic>.from(res['mobile_user']) : null;
        _brand = (res['brand'] is Map) ? Map<String, dynamic>.from(res['brand']) : null;
        _manager = (res['manager'] is Map) ? Map<String, dynamic>.from(res['manager']) : null;
        _accounts = (res['accounts'] is List) ? List<dynamic>.from(res['accounts']) : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    try {
      return _df.format(DateTime.parse(v.toString()));
    } catch (_) {
      return v.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackEmail = context.watch<UserProvider>().user?.email ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _AppDrawer(user: _user, fallbackEmail: fallbackEmail),
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.home.headerGradient),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : CustomScrollView(
                    slivers: [
                      // HERO HEADER (Profile)
                      SliverToBoxAdapter(child: _profileHeader()),

                      // spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Brand & Manager - responsive cards
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(child: _brandManagerLayout()),
                      ),

                      // spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Accounts title
                      SliverToBoxAdapter(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Instagram Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('${_accounts.length}', style: TextStyle(color: AppColors.textMedium)),
                          ],
                        ),
                      )),

                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      // Accounts grid (responsive)
                      _accounts.isEmpty
                          ? SliverToBoxAdapter(child: _emptyAccounts())
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final acc = _accounts[i];
                                    final profile = _safeDecode(acc['profile_data']);
                                    final avatar = profile?['profile_picture_url'] ?? profile?['profile_picture'];
                                    final metrics = acc['latest_metrics'] ?? {};
                                    return _accountCard(
                                      avatar: avatar,
                                      username: acc['username'] as String?,
                                      accountName: acc['account_name'] as String?,
                                      followers: metrics['followers'],
                                      posts: metrics['posts'],
                                      reach: metrics['reach'],
                                      primary: acc['is_primary'] == true || acc['is_primary'] == 1,
                                    );
                                  },
                                  childCount: _accounts.length,
                                ),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 420,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 2.6,
                                ),
                              ),
                            ),

                      // bottom spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  // ------------------------------
  // Profile header — shows ALL mobile-user info (only place it's shown)
  // ------------------------------
  Widget _profileHeader() {
    final name = _user?['name'] ?? 'Client';
    final email = _user?['email'] ?? '';
    final phone = _user?['phone']?.toString() ?? '';
    final id = _user?['id']?.toString() ?? '-';
    final active = (_user?['is_active'] == true) ? 'Active' : 'Inactive';
    final lastLogin = _user?['last_login_at'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.home.headerGradient),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row: avatar + name/email
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 28, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              // small status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(active, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile details rows (id, phone, last login,...)
          Material(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Column(
                children: [
                  _profileRow('Profile ID', id),
                  const Divider(height: 12, color: Colors.white12),
                  _profileRow('Phone', phone.isNotEmpty ? phone : '-'),
                  const Divider(height: 12, color: Colors.white12),
                  _profileRow('Last login', lastLogin != null ? _fmt(lastLogin) : '-'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white70))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    );
  }

  // ------------------------------
  // Brand + Manager layout
  // ------------------------------
  Widget _brandManagerLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _infoCard(title: 'Brand', icon: Icons.business, children: _brandInfoRows())),
            const SizedBox(width: 16),
            Expanded(child: _infoCard(title: 'Manager', icon: Icons.verified_user, children: _managerInfoRows())),
          ],
        );
      } else {
        return Column(
          children: [
            _infoCard(title: 'Brand', icon: Icons.business, children: _brandInfoRows()),
            const SizedBox(height: 12),
            _infoCard(title: 'Manager', icon: Icons.verified_user, children: _managerInfoRows()),
          ],
        );
      }
    });
  }

  List<Widget> _brandInfoRows() {
    return [
      _infoRow('Name', _brand?['name']),
      _infoRow('Description', _brand?['description']),
      _infoRow('Created', _brand?['created_at'] != null ? _fmt(_brand!['created_at']) : null),
    ];
  }

  List<Widget> _managerInfoRows() {
    return [
      _infoRow('Name', _manager?['name']),
      _infoRow('Email', _manager?['email']),
      _infoRow('User ID', _manager?['id']?.toString()),
      _infoRow('Created', _manager?['created_at'] != null ? _fmt(_manager!['created_at']) : null),
    ];
  }

  Widget _infoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.12), child: Icon(icon, color: AppColors.primary)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: TextStyle(color: AppColors.textMedium))),
        Expanded(child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }

  // ------------------------------
  // Accounts / account card
  // ------------------------------
  Widget _accountCard({
    String? avatar,
    String? username,
    String? accountName,
    dynamic followers,
    dynamic posts,
    dynamic reach,
    bool primary = false,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          // navigate to account details (existing route)
          // pass id or any identifier as needed
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              backgroundColor: AppColors.instagram.badge,
              child: avatar == null ? const Icon(Icons.camera_alt, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(children: [
                  Expanded(child: Text(username ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (primary) const Icon(Icons.star, color: Colors.amber, size: 18),
                ]),
                const SizedBox(height: 4),
                Text(accountName ?? '', style: TextStyle(color: AppColors.textMedium)),
                const SizedBox(height: 8),
                Row(children: [
                  _smallStat('Followers', followers),
                  const SizedBox(width: 12),
                  _smallStat('Posts', posts),
                  const SizedBox(width: 12),
                  _smallStat('Reach', reach),
                ])
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _smallStat(String label, dynamic value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      Text(value?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _emptyAccounts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(child: Column(children: const [Icon(Icons.camera_alt, size: 48, color: Colors.grey), SizedBox(height: 8), Text('No Instagram accounts connected')])),
    );
  }

  Widget _errorView() {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error ?? 'Error', style: const TextStyle(color: Colors.red))));
  }

  // ------------------------------
  // Utilities
  // ------------------------------
  Map<String, dynamic>? _safeDecode(dynamic pd) {
    if (pd == null) return null;
    try {
      if (pd is Map) return Map<String, dynamic>.from(pd);
      if (pd is String && pd.isNotEmpty) {
        final decoded = jsonDecode(pd);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }
}

// ---------------------------------------------------------------------------
// DRAWER
// ---------------------------------------------------------------------------
class _AppDrawer extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String fallbackEmail;
  const _AppDrawer({this.user, required this.fallbackEmail});

  @override
  Widget build(BuildContext context) {
    final name = user?['name'] ?? 'Client';
    final email = user?['email'] ?? fallbackEmail;
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        UserAccountsDrawerHeader(
          accountName: Text(name),
          accountEmail: Text(email),
          decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.home.headerGradient)),
        ),
        _drawerItem(context, Icons.home, 'Home', '/home'),
        _drawerItem(context, Icons.rss_feed, 'Social Hub', '/social-hub'),
        _drawerItem(context, Icons.bar_chart, 'Dashboard', '/dashboard'),
        _drawerItem(context, Icons.search, 'Insights', '/insights'),
        _drawerItem(context, Icons.settings, 'Settings', '/settings'),
        const Divider(),
        _drawerItem(context, Icons.logout, 'Logout', '/login'),
      ]),
    );
  }

  Widget _drawerItem(BuildContext ctx, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(ctx);
        Navigator.pushReplacementNamed(ctx, route);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// BOTTOM NAV (keeps your existing routes)
 // ---------------------------------------------------------------------------
class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({required this.currentIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 12,
      onTap: (i) {
        const routes = ['/home', '/social-hub', '/dashboard', '/insights', '/settings'];
        Navigator.pushReplacementNamed(context, routes[i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: 'Social'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Insights'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
