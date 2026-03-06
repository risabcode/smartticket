import 'package:flutter/material.dart';

class ToggleButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  ToggleButton({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Switch(value: value, onChanged: onChanged);
  }
}
