import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> allNotifications = [];
  bool isLoading = true;
  String currentUserId = '';
  String role = '';
  String department = '';
  String level = '';

  @override
  void initState() {
    super.initState();
    fetchUserAndNotifications();
  }

  Future<void> fetchUserAndNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      currentUserId = user.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      role = (userDoc['role'] ?? '').toString().toLowerCase();
      department = userDoc['department'] ?? '';
      level = userDoc['level'] ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      final filtered = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final notifUserId = data['userId'] ?? '';
        final notifTarget = (data['target'] ?? '').toString().toLowerCase();
        final notifDept = data['department'] ?? '';
        final notifLevel = data['level'] ?? '';

        // 1. Personal notification (userId == current user)
        final personal = notifUserId == currentUserId;

        // 2. Global notification for everyone
        final global = notifTarget == 'all';

        // 3. Role-based notification (for 'student' or 'lecturer')
        final roleBased = notifTarget == role;

        // 4. Department + Level-based notification (only for students)
        final deptLevelBased = role == 'student' &&
            notifTarget == 'student' &&
            notifDept == department &&
            notifLevel == level;

        return personal || global || roleBased || deptLevelBased;
      }).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        allNotifications = filtered;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching notifications: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleNotificationTap(String type) {
    if (type == 'note') {
      Navigator.pushNamed(context, '/notes');
    } else if (type == 'event') {
      Navigator.pushNamed(context, '/events');
    } else if (type == 'timetable') {
      Navigator.pushNamed(context, '/timetable');
    }
    // You can add more types if needed
  }

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allNotifications.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = allNotifications[index];
                    final isForUploader = notif['userId'] == currentUserId &&
                        (notif['message']?.contains('You') ?? false);
                    final message = isForUploader
                        ? notif['message']
                        : notif['publicMessage'] ?? notif['message'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.notifications, color: Color(0xFF307DBA)),
                        title: Text(
                          message ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Kanit'),
                        ),
                        subtitle: notif['timestamp'] != null
                            ? Text(
                                (notif['timestamp'] as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split('.')[0],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Kanit',
                                ),
                              )
                            : const Text(''),
                        onTap: () => handleNotificationTap(notif['type'] ?? ''),
                      ),
                    );
                  },
                ),
    );
  }
}
