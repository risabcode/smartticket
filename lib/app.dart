import 'package:flutter/material.dart';
import 'routes.dart';
import 'core/app_colors.dart';

class PrinsightsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrInsights',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 8,
        ),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: Routes.welcome,
      routes: Routes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
