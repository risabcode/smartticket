import 'package:flutter/material.dart';

class SentimentBar extends StatelessWidget {
  final double positive;
  final double neutral;
  final double negative;
  SentimentBar({required this.positive, required this.neutral, required this.negative});
  @override
  Widget build(BuildContext context) {
    final total = positive + neutral + negative;
    return Row(children: [
      Expanded(flex: (positive/total*100).round(), child: Container(height: 10, color: Colors.green)),
      Expanded(flex: (neutral/total*100).round(), child: Container(height: 10, color: Colors.grey)),
      Expanded(flex: (negative/total*100).round(), child: Container(height: 10, color: Colors.red)),
    ]);
  }
}
