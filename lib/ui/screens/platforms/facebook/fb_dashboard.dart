import 'package:flutter/material.dart';

class FBDashboard extends StatelessWidget {
  final bool embedded;

  const FBDashboard({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        embedded
            ? 'Facebook Dashboard (Embedded)'
            : 'Facebook Dashboard',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
