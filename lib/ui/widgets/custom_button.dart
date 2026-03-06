import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool danger;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: danger ? Colors.red : null,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
