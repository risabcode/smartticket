import 'package:flutter/material.dart';

class KPI_Card extends StatelessWidget {
  final String title;
  final String value;
  KPI_Card({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Text(title), SizedBox(height:8), Text(value, style: TextStyle(fontSize:18, fontWeight: FontWeight.bold))])));
  }
}
