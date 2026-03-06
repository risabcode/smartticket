import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text('Demo User'),
        subtitle: Text('@demo_influencer'),
      ),
    );
  }
}
