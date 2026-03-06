import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: TextStyle(color: Colors.red)));
  }
}
