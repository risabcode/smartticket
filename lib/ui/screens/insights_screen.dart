import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/platform_provider.dart';

// ✅ IMPORT THE FILES YOU CREATED
import 'platforms/facebook/fb_insights.dart';
import 'platforms/instagram/insta_insights.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlatformProvider>(context);
    final selected = provider.selectedPlatform;

    final PageTheme theme =
        _pageThemeFor(selected) ?? AppColors.insights;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ---------------- APP BAR ----------------
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
        title: Text(
          _appBarTitleFor(selected),
          style: const TextStyle(color: Colors.white),
        ),
      ),

      // ---------------- BODY ----------------
      body: selected == null
          ? const Center(
              child: Text(
                "Select a platform from Dashboard",
                style: TextStyle(fontSize: 16),
              ),
            )
          : _buildInsightsForPlatform(selected),

      bottomNavigationBar: const _BottomNav(currentIndex: 3),
    );
  }

  // ---------------- PLATFORM SWITCH ----------------
  Widget _buildInsightsForPlatform(String platform) {
    switch (platform) {
      case 'facebook':
        return FBInsights();
      case 'instagram':
        return InstaInsights();
      default:
        return const Center(child: Text("No insights available"));
    }
  }

  // ---------------- TITLE ----------------
  String _appBarTitleFor(String? p) {
    switch (p) {
      case 'facebook':
        return "Facebook Insights";
      case 'instagram':
        return "Instagram Insights";
      default:
        return "Insights";
    }
  }

  // ---------------- THEME ----------------
  PageTheme? _pageThemeFor(String? p) {
    switch (p) {
      case 'facebook':
        return AppColors.facebook;
      case 'instagram':
        return AppColors.instagram;
      default:
        return AppColors.insights;
    }
  }
}

// ---------------- BOTTOM NAV ----------------
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: 'Social Hub'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Insights'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
