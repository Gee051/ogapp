import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'events_screen.dart';
import 'school_screen.dart';
import 'me_screen.dart';

class MainAppScreen extends StatefulWidget {
  final String userFirstName;
  final String userRole;
  final String userDepartment;
  final String userLevel;
  final String currentUserId; 

  const MainAppScreen({super.key, required this.userFirstName, required this.userRole, required this.userDepartment, required this.userLevel, required this.currentUserId});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        userFirstName: widget.userFirstName,
        onSeeMoreTapped: () {
          setState(() => _currentIndex = 1); // Navigate to Events tab
        },
      ),
      const EventsScreen(),
      SchoolScreen(),
      MeScreen(
      userFirstName: widget.userFirstName,
      userRole: widget.userRole,
      userDepartment: widget.userDepartment,
      userLevel: widget.userLevel,
      currentUserId: widget.currentUserId,

    ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Academics'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
