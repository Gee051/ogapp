import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StudentRepScreen extends StatefulWidget {
  const StudentRepScreen({super.key});

  @override
  State<StudentRepScreen> createState() => _StudentRepScreenState();
}

class _StudentRepScreenState extends State<StudentRepScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> departmentReps = [];
  String currentDept = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCurrentLecturerDepartment();
  }

  Future<void> fetchCurrentLecturerDepartment() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    currentDept = doc['department'];
    fetchRepsInDepartment();
  }

  Future<void> fetchRepsInDepartment() async {
    final repsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .where('department', isEqualTo: currentDept)
        .get();

    setState(() {
      departmentReps = repsSnapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
      isLoading = false;
    });
  }

  Future<void> assignAsAdmin(Map<String, dynamic> studentData) async {
    final docId = studentData['uid'];
    final docRef = FirebaseFirestore.instance.collection('users').doc(docId);
    final exists = (await docRef.get()).exists;

    if (!exists) {
      Fluttertoast.showToast(msg: "User no longer exists.");
      return;
    }

    await docRef.update({'isAdmin': true});

    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'admin_assignment',
      'message': 'You have been assigned as a Student Rep',
      'userId': docId,
      'timestamp': Timestamp.now(),
      'target': 'student',
    });

    Fluttertoast.showToast(msg: "✅ Student rep assigned successfully");
    fetchRepsInDepartment();
    setState(() => allUsers = []); // Clear search list after assigning
  }

  Future<void> removeAsAdmin(Map<String, dynamic> studentData) async {
    final docId = studentData['uid'];
    final docRef = FirebaseFirestore.instance.collection('users').doc(docId);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Student Rep"),
        content: Text(
            "Are you sure you want to remove ${studentData['fullName']} from student reps?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await docRef.update({'isAdmin': false});
              await FirebaseFirestore.instance.collection('notifications').add({
                'type': 'admin_removal',
                'message': 'You have been removed as a Student Rep',
                'userId': docId,
                'timestamp': Timestamp.now(),
                'target': 'student',
              });

              Fluttertoast.showToast(msg: "🚫 Student rep removed");
              fetchRepsInDepartment();
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => allUsers = []);
      return;
    }

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('department', isEqualTo: currentDept)
        .get();

    final matches = result.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .where((user) =>
            user['fullName'].toLowerCase().contains(query.toLowerCase()) &&
            user['isAdmin'] != true)
        .toList();

    setState(() {
      allUsers = matches;
    });
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
            title: const Text(
              'Student Reps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search student by name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: searchUsers,
            ),
            const SizedBox(height: 20),
            if (allUsers.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final student = allUsers[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(student['fullName'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Level: ${student['level']} • Matric: ${student['matricNumber']}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700),
                          onPressed: () => assignAsAdmin(student),
                          child: const Text('Assign',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (allUsers.isNotEmpty) const SizedBox(height: 30),
            const Divider(thickness: 1.5),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  'Current Student Reps',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFamily: 'Kanit',
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (departmentReps.isEmpty)
              const Text('No student reps yet in this department.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: departmentReps.length,
                  itemBuilder: (context, index) {
                    final student = departmentReps[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.verified_user,
                            color: Colors.green),
                        title: Text(student['fullName'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            "Level: ${student['level']} • Matric: ${student['matricNumber']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => removeAsAdmin(student),
                          tooltip: 'Remove Student Rep',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
