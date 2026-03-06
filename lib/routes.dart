import 'package:flutter/material.dart';

import 'ui/screens/welcome_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/register_screen.dart'; // ✅ ADD
import 'ui/screens/home_screen.dart';
import 'ui/screens/social_hub_screen.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/insights_screen.dart';
import 'ui/screens/settings_screen.dart';

class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register'; // ✅ ADD
  static const home = '/home';
  static const socialHub = '/social-hub';
  static const dashboard = '/dashboard';
  static const insights = '/insights';
  static const settings = '/settings';

  static final routes = <String, WidgetBuilder>{
    welcome: (_) => const WelcomeScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(), // ✅ ADD
    home: (_) => const HomeScreen(),
    socialHub: (_) => const SocialHubScreen(),
    dashboard: (_) => const DashboardScreen(),
    insights: (_) => const InsightsScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
