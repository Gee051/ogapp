import 'package:flutter/material.dart';
import 'about_app_screen.dart';
import 'feedback_screen.dart';
import 'find_og_screen.dart';
import 'notifications_screen.dart';
import 'personal_details_screen.dart';
import 'saved_notes_screen.dart';
import 'timetable_screen.dart';
import 'login_screen.dart';
import 'student_rep_screen.dart';
import 'assignments_screen.dart';
import 'student_submissions_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class MeScreen extends StatelessWidget {
  final String userFirstName;
  final String userRole;
  final String userDepartment;
  final String userLevel;
  final String currentUserId; 

  const MeScreen({
    super.key,
    required this.userFirstName,
    required this.userRole,
    required this.userDepartment,
    required this.userLevel,
    required this.currentUserId,
  });

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLecturer = userRole.toLowerCase() == 'lecturer';

    final List<Map<String, dynamic>> commonItems = [
      {
        'icon': Icons.person,
        'label': 'Personal Details',
        'builder': (context) => const PersonalDetailsScreen(),
      },
      {
        'icon': Icons.schedule,
        'label': 'Timetable',
        'builder': (context) => const TimetableScreen(),
      },
      {
        'icon': Icons.assignment,
        'label': 'Assignments',
        'builder': (context) => AssignmentScreen(
          userRole: userRole,
          userDepartment: userDepartment,
          userLevel: userLevel,
          currentUserId: currentUserId,
        ),
      },
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'builder': (context) => const NotificationsScreen(),
      },
      {
        'icon': Icons.info,
        'label': 'About App',
        'builder': (context) => const AboutAppScreen(),
      },
      {
        'icon': isLecturer ? Icons.upload_file : Icons.bookmark,
        'label': isLecturer ? 'Student Submissions' : 'Saved Notes',
        'builder': (context) =>
            isLecturer ? const StudentSubmissionsScreen() : const SavedNotesScreen(),
      },
      {
        'icon': Icons.feedback,
        'label': 'Feedback',
        'builder': (context) => const FeedbackScreen(),
      },
    ];

    final conditionalItem = isLecturer
        ? {
            'icon': Icons.star,
            'label': 'Student Rep',
            'builder': (context) => const StudentRepScreen(),
          }
        : {
            'icon': Icons.group,
            'label': 'Find an OG',
            'builder': (context) => const FindOGScreen(),
          };

    final items = [...commonItems, conditionalItem];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5EBCE2), Color(0xFF307DBA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              userFirstName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index < items.length) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Icon(item['icon'] as IconData, color: const Color(0xFF307DBA)),
                title: Text(
                  item['label'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Kanit', fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['builder'](context)),
                ),
              ),
            );
          } else {
            return Card(
              color: Colors.red.shade100,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Kanit', fontSize: 18),
                ),
                onTap: () => _logout(context),
              ),
            );
          }
        },
      ),
    );
  }
}
