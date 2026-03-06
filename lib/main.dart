import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/user_provider.dart';
import 'providers/platform_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/sentiment_provider.dart';
import 'providers/selected_account_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        // 🔐 Auth / user
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // 🌐 Platform provider
        ChangeNotifierProvider(
          create: (_) {
            final provider = PlatformProvider();

            // Meta App credentials
            provider.setMetaAppCredentials(
              appId: dotenv.env['META_APP_ID'] ?? '',
              appSecret: dotenv.env['META_APP_SECRET'] ?? '',
            );

            // Instagram connection (optional)
            final igToken = dotenv.env['INSTAGRAM_GRAPH_ACCESS_TOKEN'];
            if (igToken != null && igToken.isNotEmpty) {
              provider.connectInstagram(igToken);
            }

            return provider;
          },
        ),

        // 📊 Dashboard data
        ChangeNotifierProvider(create: (_) => DashboardProvider()),

        // 💬 Sentiment analysis
        ChangeNotifierProvider(create: (_) => SentimentProvider()),

        // 📸 ✅ SELECTED INSTAGRAM ACCOUNT (NEW)
        ChangeNotifierProvider(create: (_) => SelectedAccountProvider()),
      ],
      child: PrinsightsApp(),
    ),
  );
}
