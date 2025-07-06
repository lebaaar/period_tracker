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
    return widget.isSelected
        ? Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb),
                SizedBox(width: 100),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isOn = !isOn;
                    });
                  },
                  child: isOn
                      ? Text(
                          'Light is ON',
                          style: TextStyle(color: Colors.white),
                        )
                      : Text('Light is OFF'),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
