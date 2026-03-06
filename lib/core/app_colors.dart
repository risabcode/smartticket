import 'package:flutter/material.dart';

class AppColors {
  // ───────────────────────────────────────────────
  // BRAND COLORS (UNIVERSAL)
  // ───────────────────────────────────────────────
  static const Color primary     = Color(0xFF2563EB);
  static const Color secondary   = Color(0xFF4F46E5);
  static const Color accent      = Color(0xFF06B6D4);

  static const Color brandBlue   = Color(0xFF3B82F6);
  static const Color brandIndigo = Color(0xFF6366F1);
  static const Color brandCyan   = Color(0xFF0EA5E9);
  static const Color brandTeal   = Color(0xFF14B8A6);

  // ───────────────────────────────────────────────
  // NEUTRAL / GREY SCALE
  // ───────────────────────────────────────────────
  static const Color background  = Color(0xFFF8FAFC);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color card        = Color(0xFFFFFFFF);
  static const Color border      = Color(0xFFE2E8F0);

  static const Color textDark    = Color(0xFF1E293B);
  static const Color textMedium  = Color(0xFF475569);
  static const Color textLight   = Color(0xFF94A3B8);

  static const Color grey1       = Color(0xFFF1F5F9);
  static const Color grey2       = Color(0xFFE2E8F0);
  static const Color grey3       = Color(0xFFCBD5E1);
  static const Color grey4       = Color(0xFF64748B);

  // ───────────────────────────────────────────────
  // STATUS COLORS
  // ───────────────────────────────────────────────
  static const Color positive = Color(0xFF22C55E);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color negative = Color(0xFFEF4444);
  static const Color info     = Color(0xFF0EA5E9);
  static const Color neutral  = Color(0xFF6B7280);

  // ───────────────────────────────────────────────
  // GRADIENTS
  // ───────────────────────────────────────────────
  static const Color gradStart = Color(0xFF3B82F6);
  static const Color gradMid   = Color(0xFF6366F1);
  static const Color gradEnd   = Color(0xFF06B6D4);

  static const List<Color> gradientPrimary = [gradStart, gradMid, gradEnd];
  static const List<Color> gradientSecondary = [brandTeal, brandCyan, brandBlue];

  static const List<Color> glow = [
    Color(0xFF60A5FA),
    Color(0xFF818CF8),
  ];

  // ───────────────────────────────────────────────
  // PAGE THEMES
  // ───────────────────────────────────────────────

  // Home
  static const home = PageTheme(
    headerGradient: [brandBlue, brandIndigo, brandCyan],
    badge: brandBlue,
    icon: brandIndigo,
  );

  // Dashboard (REFERENCE BASE)
  static const dashboard = PageTheme(
    headerGradient: [brandCyan, brandTeal, brandBlue],
    badge: brandTeal,
    icon: brandCyan,
  );

  // Insights — NOW MATCHES DASHBOARD
  static const insights = PageTheme(
    headerGradient: [brandCyan, brandTeal, brandBlue],
    badge: brandTeal,
    icon: brandCyan,
  );

  // Settings
  static const settings = PageTheme(
    headerGradient: [
      Color(0xFF334155),
      Color(0xFF475569),
      Color(0xFF64748B),
    ],
    badge: Color(0xFF475569),
    icon: Color(0xFF334155),
  );

  // Platform-specific themes
  static const youtube = PageTheme(
    headerGradient: [Color(0xFFDC2626), Color(0xFFB91C1C), Color(0xFF7F1D1D)],
    badge: Color(0xFFDC2626),
    icon: Color(0xFFB91C1C),
  );

  static const facebook = PageTheme(
    headerGradient: [Color(0xFF1877F2), Color(0xFF0A66C2), Color(0xFF1A5DB0)],
    badge: Color(0xFF1877F2),
    icon: Color(0xFF0A66C2),
  );

  static const instagram = PageTheme(
    headerGradient: [brandBlue, brandIndigo, brandCyan],
    badge: brandIndigo,
    icon: brandCyan,
  );

  static const twitter = PageTheme(
    headerGradient: [Color(0xFF1DA1F2), brandCyan, Color(0xFF0284C7)],
    badge: Color(0xFF1DA1F2),
    icon: Color(0xFF0284C7),
  );
}

// PAGE THEME MODEL
class PageTheme {
  final List<Color> headerGradient;
  final Color badge;
  final Color icon;

  const PageTheme({
    required this.headerGradient,
    required this.badge,
    required this.icon,
  });
}
