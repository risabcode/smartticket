// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/platform_provider.dart';

// Platform dashboards
import 'platforms/facebook/fb_dashboard.dart';
import 'platforms/instagram/insta_dashboard.dart';

///////////////////////////////////////////////////////////////////////////////
// BOTTOM NAV
///////////////////////////////////////////////////////////////////////////////
class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({required this.currentIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 12,
      onTap: (i) {
        switch (i) {
          case 0:
            Navigator.pushNamed(context, '/home');
            break;
          case 1:
            Navigator.pushNamed(context, '/social-hub');
            break;
          case 2:
            Navigator.pushNamed(context, '/dashboard');
            break;
          case 3:
            Navigator.pushNamed(context, '/insights');
            break;
          case 4:
            Navigator.pushNamed(context, '/settings');
            break;
        }
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

///////////////////////////////////////////////////////////////////////////////
// MAIN DASHBOARD SCREEN
///////////////////////////////////////////////////////////////////////////////
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedPlatform;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlatformProvider>(context);
    final connectedPlatforms = provider.connectedPlatforms;

    // Keep selection in sync with provider; do minimal setState inside a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // if provider changed, mirror it
      if (_selectedPlatform != provider.selectedPlatform) {
        setState(() => _selectedPlatform = provider.selectedPlatform);
        return;
      }

      // initial pick when nothing selected
      if (_selectedPlatform == null && connectedPlatforms.isNotEmpty) {
        final pick = connectedPlatforms.first;
        setState(() => _selectedPlatform = pick);
        provider.selectedPlatform = pick;
        return;
      }

      // if current selection was removed, fallback
      if (_selectedPlatform != null && !connectedPlatforms.contains(_selectedPlatform)) {
        final fallback = connectedPlatforms.isNotEmpty ? connectedPlatforms.first : null;
        setState(() => _selectedPlatform = fallback);
        provider.selectedPlatform = fallback;
      }
    });

    final PageTheme theme = _pageThemeFor(_selectedPlatform) ?? AppColors.dashboard;
    final String title = _appBarTitleFor(_selectedPlatform);

    return Scaffold(
      backgroundColor: AppColors.background,
      ///////////////////////////////////////////////////////////////////////////
      // APP BAR
      ///////////////////////////////////////////////////////////////////////////
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.badge,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (connectedPlatforms.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: PlatformPill(
                  platforms: connectedPlatforms,
                  value: _selectedPlatform,
                  onChanged: (value) {
                    setState(() => _selectedPlatform = value);
                    provider.selectedPlatform = value;
                  },
                ),
              )
            else
              const DisabledPill(),
          ],
        ),
      ),

      ///////////////////////////////////////////////////////////////////////////
      // BODY
      ///////////////////////////////////////////////////////////////////////////
      body: _buildBody(connectedPlatforms),

      ///////////////////////////////////////////////////////////////////////////
      // BOTTOM NAV
      ///////////////////////////////////////////////////////////////////////////
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  /////////////////////////////////////////////////////////////////////////////
  // BODY BUILDER
  /////////////////////////////////////////////////////////////////////////////
  Widget _buildBody(List<String> connectedPlatforms) {
    if (connectedPlatforms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Connect a platform from the Social Hub to view your analytics here.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    if (_selectedPlatform == null) {
      return const Center(child: Text("Select a platform from the dropdown."));
    }

    switch (_selectedPlatform) {
      case 'facebook':
        // removed const to avoid "not constant expression" if FBDashboard lacks const constructor
        return FBDashboard(embedded: true);
      case 'instagram':
        // ensure we don't use const here — InstaDashboardCompact likely doesn't have a const ctor
        return InstaDashboardCompact();
      default:
        return const Center(child: Text("No dashboard available."));
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // TITLE
  /////////////////////////////////////////////////////////////////////////////
  String _appBarTitleFor(String? p) {
    switch (p) {
      case 'facebook':
        return "Facebook";
      case 'instagram':
        return "Instagram";
      default:
        return "Dashboard";
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // THEME
  /////////////////////////////////////////////////////////////////////////////
  PageTheme? _pageThemeFor(String? p) {
    switch (p) {
      case 'facebook':
        return AppColors.facebook;
      case 'instagram':
        return AppColors.instagram;
      default:
        return AppColors.dashboard;
    }
  }
}

///////////////////////////////////////////////////////////////////////////////
// PLATFORM PILL
///////////////////////////////////////////////////////////////////////////////
class PlatformPill extends StatelessWidget {
  final List<String> platforms;
  final String? value;
  final ValueChanged<String?> onChanged;

  const PlatformPill({
    required this.platforms,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? platforms.first;

    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 45),
      itemBuilder: (_) {
        return platforms.map((p) {
          return PopupMenuItem<String>(
            value: p,
            child: Row(
              children: [
                _platformIcon(p),
                const SizedBox(width: 8),
                Text(p[0].toUpperCase() + p.substring(1)),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _platformIcon(current),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                current[0].toUpperCase() + current.substring(1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _platformIcon(String p) {
    switch (p) {
      case 'instagram':
        return CircleIcon(icon: Icons.camera_alt, bg: AppColors.instagram.badge);
      case 'facebook':
        return CircleIcon(icon: Icons.facebook, bg: AppColors.facebook.badge);
      default:
        return CircleIcon(icon: Icons.device_hub, bg: AppColors.primary);
    }
  }
}

class DisabledPill extends StatelessWidget {
  const DisabledPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: const Text(
        "No platforms",
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color bg;

  const CircleIcon({required this.icon, required this.bg, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}