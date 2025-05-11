import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:og/get_started_screen.dart';
// import 'auth_check.dart'; // 👈 import the auth check screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OG - your study guy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF307DBA),
          brightness: Brightness.light,
        ).copyWith(
          surfaceTint: Colors.transparent,
        ),
        dialogBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5EBCE2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const GetStartedScreen(), // 👈 Replace GetStartedScreen with AuthCheck
    );
  }
}
