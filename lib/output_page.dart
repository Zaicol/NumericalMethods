import 'package:flutter/material.dart';
import 'package:numerical_analysis/some_widgets.dart';

class OutputPage extends StatefulWidget {
  const OutputPage({super.key});

  @override
  OutputPageState createState() => OutputPageState();
}

class OutputPageState extends State<OutputPage> {
  String text = "Здесь выводятся логи.\n";

  void addToOutputField(String message) {
    setState(() {
      text += '\n$message';
    });
  }

  void clearOutputField() {
    setState(() {
      text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(
                text,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          CustomElevatedButton(
            label: 'Очистить',
            onPressed: clearOutputField,
          ),
        ],
      ),
    );
  }
}