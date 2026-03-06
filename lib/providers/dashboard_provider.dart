import 'package:flutter/material.dart';
import '../models/analytics_model.dart';

class DashboardProvider extends ChangeNotifier {
  AnalyticsModel? analytics;

  void setAnalytics(AnalyticsModel data) {
    analytics = data;
    notifyListeners();
  }
}
