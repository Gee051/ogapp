import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'upload_timetable_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String userRole = '';
  String userDept = '';
  String userLevel = '';
  String userId = '';
  String userName = '';
  bool isAdmin = false;
  bool isLoading = true;
  List<Map<String, dynamic>> timetables = [];

  @override
  void initState() {
    super.initState();
    fetchUserAndTimetables();
  }

  Future<void> fetchUserAndTimetables() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      userId = user.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data()!;
      userRole = data['role'];
      userDept = data['department'];
      userLevel = data['level'] ?? '';
      userName = data['fullName'].split(" ").first;
      isAdmin = data['isAdmin'] == true;

      QuerySnapshot snapshot;

      if (userRole == 'lecturer') {
        snapshot = await FirebaseFirestore.instance
            .collection('timetables')
            .where('department', isEqualTo: userDept)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('timetables')
            .where('department', isEqualTo: userDept)
            .where('level', isEqualTo: userLevel)
            .orderBy('timestamp', descending: true)
            .get();
      }

      setState(() {
        timetables = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('🔥 Error fetching timetable: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteTimetable(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('timetables')
          .doc(docId)
          .delete();

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'timetable',
        'message': '$userName deleted a timetable',
        'timestamp': Timestamp.now(),
        'target': 'student',
        'department': userDept,
        'level': userLevel,
      });

      fetchUserAndTimetables();
    } catch (e) {
      print("❌ Failed to delete timetable: $e");
    }
  }

  Widget buildDayCourses(Map<String, dynamic> daysMap) {
    const orderedDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: orderedDays.where((day) => daysMap.containsKey(day)).map((day) {
        final courses = daysMap[day] as List<dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              day.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF307DBA),
              ),
            ),
            ...courses.map((course) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "${course['code']} - ${course['title']} (${course['time']})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Kanit',
                    fontSize: 17,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
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
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text(
              'Timetable',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
            actions: [
              if (userRole == 'student' && isAdmin)
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UploadTimetableScreen(),
                      ),
                    ).then((_) => fetchUserAndTimetables());
                  },
                ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : timetables.isEmpty
              ? const Center(child: Text('No timetable available yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: timetables.length,
                  itemBuilder: (context, index) {
                    final t = timetables[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['heading'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Kanit',
                              ),
                            ),
                            Text("Level: ${t['level']}"),
                            const SizedBox(height: 10),
                            buildDayCourses(t['days'] ?? {}),
                            const SizedBox(height: 10),
                            if (userRole == 'student' &&
                                isAdmin &&
                                t['createdBy'] == userId)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UploadTimetableScreen(
                                              editData: t),
                                        ),
                                      ).then((_) => fetchUserAndTimetables());
                                    },
                                    child: const Text('Edit',
                                        style: TextStyle(color: Colors.orange)),
                                  ),
                                  TextButton(
                                    onPressed: () => deleteTimetable(t['id']),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
