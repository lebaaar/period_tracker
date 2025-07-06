import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final bool isSelected;
  const ProfilePage({super.key, required this.isSelected});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Profile page'));
  }
}
