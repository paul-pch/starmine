import 'package:flutter/material.dart';

void main() {
  runApp(const StarmineApp());
}

class StarmineApp extends StatelessWidget {
  const StarmineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Starmine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5C451),
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(body: Center(child: Text('Starmine'))),
    );
  }
}
