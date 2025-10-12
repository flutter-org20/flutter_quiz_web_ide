import 'package:flutter/material.dart';
import 'package:quiz_web_app/quiz_screen.dart';

void main() {
  runApp(const QuizWebApp());
}

class QuizWebApp extends StatelessWidget {
  const QuizWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Quiz Web App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const QuizScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
