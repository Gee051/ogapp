import 'package:flutter/material.dart';

class LecturerDashboard extends StatelessWidget {
  const LecturerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lecturer Dashboard"),
      ),
      body: Center(
        child: Text(
          "Welcome to the Lecturer Dashboard!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
