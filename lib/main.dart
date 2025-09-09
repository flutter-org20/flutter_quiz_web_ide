import 'package:flutter/material.dart';
import 'package:python_web_ide/ide_screen.dart';

void main() {
  runApp(const PythonWebIDE());
}

class PythonWebIDE extends StatelessWidget {
  const PythonWebIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Web IDE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const IDEScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
