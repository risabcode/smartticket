import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SentimentPieChart extends StatelessWidget {
  final int positive;
  final int neutral;
  final int negative;
  final int toxic;

  const SentimentPieChart({
    super.key,
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.toxic,
  });

  @override
  Widget build(BuildContext context) {
    final total = positive + neutral + negative + toxic;

    if (total == 0) {
      return const Center(child: Text("No sentiment data"));
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: positive.toDouble(),
              color: Colors.green,
              title: "P\n${_pct(positive, total)}",
              radius: 55,
            ),
            PieChartSectionData(
              value: neutral.toDouble(),
              color: Colors.grey,
              title: "N\n${_pct(neutral, total)}",
              radius: 55,
            ),
            PieChartSectionData(
              value: negative.toDouble(),
              color: Colors.orange,
              title: "Neg\n${_pct(negative, total)}",
              radius: 55,
            ),
            PieChartSectionData(
              value: toxic.toDouble(),
              color: Colors.red,
              title: "Tox\n${_pct(toxic, total)}",
              radius: 55,
            ),
          ],
        ),
      ),
    );
  }

  String _pct(int val, int total) {
    if (total == 0) return "0%";
    return "${((val / total) * 100).round()}%";
  }
}
