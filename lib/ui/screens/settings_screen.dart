import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ─────────────────────────────────────────────
      // RESPONSIVE AESTHETIC HEADER (Gradient)
      // ─────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 110 : 130),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.settings.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18 : 26,
                vertical: isMobile ? 14 : 18,
              ),
              child: Row(
                children: [
                  // BACK BUTTON
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),

                  SizedBox(width: isMobile ? 14 : 20),

                  // TITLE
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const Spacer(),

                  Icon(Icons.settings,
                      color: Colors.white.withOpacity(.9),
                      size: isMobile ? 26 : 30),
                ],
              ),
            ),
          ),
        ),
      ),

      // ─────────────────────────────────────────────
      // BODY CONTENT
      // ─────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 16 : 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _sectionTitle("Account", isMobile: isMobile),
            const SizedBox(height: 12),

            _settingCard(
              title: "Profile",
              subtitle: "View or edit your basic information",
              icon: Icons.person,
              color: AppColors.primary,
              isMobile: isMobile,
              onTap: () {},
            ),

            SizedBox(height: isMobile ? 22 : 28),

            _sectionTitle("Preferences", isMobile: isMobile),
            const SizedBox(height: 12),

            _settingCard(
              title: "Notifications",
              subtitle: "Manage push alerts and updates",
              icon: Icons.notifications_active,
              color: AppColors.brandCyan,
              isMobile: isMobile,
              onTap: () {},
            ),

            _settingCard(
              title: "Privacy Settings",
              subtitle: "Control what data you share",
              icon: Icons.lock,
              color: AppColors.brandIndigo,
              isMobile: isMobile,
              onTap: () {},
            ),

            SizedBox(height: isMobile ? 40 : 50),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION TITLE (adaptive text size)
  // ─────────────────────────────────────────────
  Widget _sectionTitle(String text, {required bool isMobile, bool danger = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: isMobile ? 17 : 19,
            fontWeight: FontWeight.w700,
            color: danger ? AppColors.negative : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 1.3,
          color: danger
              ? AppColors.negative.withOpacity(.25)
              : AppColors.grey3.withOpacity(.35),
        )
      ],
    );
  }

  // ─────────────────────────────────────────────
  // RESPONSIVE MODERN SETTING CARD
  // ─────────────────────────────────────────────
  Widget _settingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ICON BADGE
            Container(
              width: isMobile ? 42 : 48,
              height: isMobile ? 42 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(.15),
                    color.withOpacity(.08),
                  ],
                ),
              ),
              child: Icon(icon, color: color, size: isMobile ? 20 : 24),
            ),

            SizedBox(width: isMobile ? 14 : 18),

            // TEXT BLOCK
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 15.5 : 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: isMobile ? 12.5 : 14,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios,
                size: isMobile ? 15 : 17,
                color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
