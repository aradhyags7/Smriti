import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MindGamesApp());
}

class MindGamesApp extends StatelessWidget {
  const MindGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindGames',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.tealAccent,
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
