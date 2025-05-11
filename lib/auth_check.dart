import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'get_started_screen.dart';
import 'main_app_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<Map<String, String>?> _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final fullName = userDoc.data()?['fullName'] ?? '';
      final role = userDoc.data()?['role'] ?? '';
      final department = userDoc.data()?['department'] ?? '';
      final level = userDoc.data()?['level'] ?? '';
      final currentUserId = FirebaseAuth.instance.currentUser!.uid; 

      return {
        'firstName': fullName.split(" ").first,
        'role': role,
        'department': department,
        'level': level,
        'currentUserId':currentUserId
        
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const GetStartedScreen();
    }

    return FutureBuilder<Map<String, String>?>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userInfo = snapshot.data;
        final firstName = userInfo?['firstName'] ?? 'User';
        final role = userInfo?['role'] ?? '';
        final department = userInfo?['department'] ?? '';
        final level = userInfo?['level'] ?? '';
        final currentUserId = FirebaseAuth.instance.currentUser!.uid; 

        return MainAppScreen(
          userFirstName: firstName,
          userRole: role,
          userDepartment: department,
          userLevel: level,
          currentUserId: currentUserId, 
        );
      },
    );
  }
}
