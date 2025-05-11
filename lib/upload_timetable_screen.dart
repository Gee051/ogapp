import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UploadTimetableScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;

  const UploadTimetableScreen({super.key, this.editData});

  @override
  State<UploadTimetableScreen> createState() => _UploadTimetableScreenState();
}

class _UploadTimetableScreenState extends State<UploadTimetableScreen> {
  final TextEditingController headingController = TextEditingController();
  final Map<String, List<Map<String, String>>> dayCourses = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
  };

  String userDept = '';
  String userLevel = '';
  String userId = '';
  String fullName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      userId = user.uid;
      userDept = doc['department'];
      userLevel = doc['level'];
      fullName = doc['fullName'] ?? 'A student';

      if (widget.editData != null) {
        headingController.text = widget.editData!['heading'];
        final days = widget.editData!['days'] as Map<String, dynamic>;
        days.forEach((key, value) {
          dayCourses[key] = List<Map<String, String>>.from(
            value.map((item) => Map<String, String>.from(item)),
          );
        });
      }
    }

    setState(() => isLoading = false);
  }

  void addCourse(String day) {
    showDialog(
      context: context,
      builder: (_) {
        final codeController = TextEditingController();
        final titleController = TextEditingController();
        final timeController = TextEditingController();

        return AlertDialog(
          title: Text("Add Course to $day"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeController, decoration: const InputDecoration(labelText: "Course Code")),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Course Title")),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: "Time")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (codeController.text.isNotEmpty &&
                    titleController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  setState(() {
                    dayCourses[day]?.add({
                      'code': codeController.text,
                      'title': titleController.text,
                      'time': timeController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveTimetable() async {
    if (headingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Heading is required");
      return;
    }

    setState(() => isLoading = true);

    final timetableData = {
      'heading': headingController.text.trim(),
      'department': userDept,
      'level': userLevel,
      'createdBy': userId,
      'timestamp': Timestamp.now(),
      'days': dayCourses,
    };

    try {
      if (widget.editData != null) {
        await FirebaseFirestore.instance
            .collection('timetables')
            .doc(widget.editData!['id'])
            .update(timetableData);

        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'timetable',
          'message': 'You updated a timetable',
          'timestamp': Timestamp.now(),
          'target': 'student',
          'department': userDept,
          'level': userLevel,
          'userId': userId,
          'publicMessage': '$fullName updated the timetable',
        });

        Fluttertoast.showToast(msg: "Timetable updated successfully");
      } else {
        await FirebaseFirestore.instance.collection('timetables').add(timetableData);

        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'timetable',
          'message': 'You uploaded a timetable',
          'timestamp': Timestamp.now(),
          'target': 'student',
          'department': userDept,
          'level': userLevel,
          'userId': userId,
          'publicMessage': '$fullName uploaded a new timetable',
        });

        Fluttertoast.showToast(msg: "Timetable uploaded successfully");
      }

      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to save timetable: $e");
      setState(() => isLoading = false);
    }
  }

  Widget buildCourseList(String day) {
    final courses = dayCourses[day]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          day,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Kanit',
            color: Color(0xFF307DBA),
          ),
        ),
        const SizedBox(height: 4),
        ...courses.map((course) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 6),
            child: Text(
              "${course['code']} - ${course['title']}\nTime: ${course['time']}",
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontFamily: 'Kanit',
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => addCourse(day),
            icon: const Icon(Icons.add, size: 18, color: Colors.orange),
            label: const Text("Add Course", style: TextStyle(color: Colors.orange)),
          ),
        ),
        const Divider(thickness: 1),
      ],
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.editData != null ? 'Edit Timetable' : 'Upload Timetable',
              style: const TextStyle(
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: headingController,
                    decoration: InputDecoration(
                      hintText: 'Enter timetable heading...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
                      .map((day) => buildCourseList(day))
                      .toList(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF307DBA),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: saveTimetable,
                    child: Text(
                      widget.editData != null ? "Update Timetable" : "Save Timetable",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
