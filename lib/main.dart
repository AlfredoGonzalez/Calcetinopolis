import 'package:flutter/material.dart';

/// F0/F1: solo núcleo de economía. La UI jugable llega en F2.
void main() => runApp(const CalcetinopolisApp());

class CalcetinopolisApp extends StatelessWidget {
  const CalcetinopolisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcetinópolis',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF7EC8E3)),
      home: const Scaffold(body: Center(child: Text('Calcetinópolis'))),
    );
  }
}
