import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final bool isSelected;
  const HomePage({super.key, required this.isSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Home page'));
  }
}
