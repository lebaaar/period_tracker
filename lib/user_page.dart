import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  final bool isSelected;
  const UserPage({super.key, required this.isSelected});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return widget.isSelected
        ? Center(
            child: Text(
              'User',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          )
        : const SizedBox.shrink();
  }
}
