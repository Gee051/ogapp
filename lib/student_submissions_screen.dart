import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentSubmissionsScreen extends StatefulWidget {
  const StudentSubmissionsScreen({super.key});

  @override
  State<StudentSubmissionsScreen> createState() => _StudentSubmissionsScreenState();
}

class _StudentSubmissionsScreenState extends State<StudentSubmissionsScreen> {
  late Future<List<QueryDocumentSnapshot>> submissionsFuture;
  String? selectedLevel;

  final List<String> levels = ['100', '200', '300', '400', '500'];

  @override
  void initState() {
    super.initState();
    submissionsFuture = fetchLecturerSubmissions();
  }

  Future<List<QueryDocumentSnapshot>> fetchLecturerSubmissions() async {
    final lecturerId = FirebaseAuth.instance.currentUser!.uid;

    final assignmentsSnap = await FirebaseFirestore.instance
        .collection('assignments')
        .where('uploadedBy', isEqualTo: lecturerId)
        .get();

    final assignmentIds = assignmentsSnap.docs.map((doc) => doc.id).toList();

    if (assignmentIds.isEmpty) return [];

    Query query = FirebaseFirestore.instance
        .collection('assignment_submissions')
        .where('assignmentId', whereIn: assignmentIds)
        .orderBy('submittedAt', descending: true);

    if (selectedLevel != null) {
      query = query.where('level', isEqualTo: selectedLevel);
    }

    final submissionsSnap = await query.get();
    return submissionsSnap.docs;
  }

  void openFileUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void showSubmissionDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          data['studentName'] ?? 'Student',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Matric No: ${data['studentId']}", style: const TextStyle(fontSize: 16)),
              Text("Course: ${data['course']}", style: const TextStyle(fontSize: 16)),
              Text("Department: ${data['department']}", style: const TextStyle(fontSize: 16)),
              Text("Level: ${data['level']}", style: const TextStyle(fontSize: 16)),
              Text("Submitted At: ${data['submittedAt'].toDate()}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              if (data['textAnswer'] != null && data['textAnswer'].toString().trim().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Text Answer:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(data['textAnswer'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                  ],
                ),
              if (data['fileUrl'] != null && data['fileUrl'].toString().isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => openFileUrl(data['fileUrl']),
                  icon: const Icon(Icons.download),
                  label: const Text("Download File"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void applyFilter(String? newLevel) {
    setState(() {
      selectedLevel = newLevel;
      submissionsFuture = fetchLecturerSubmissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Submissions', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF307DBA),
      ),
      body: Column(
        children: [
          // 🔍 Level Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text("Filter by Level:", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedLevel,
                  hint: const Text("All Levels"),
                  onChanged: applyFilter,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All")),
                    ...levels.map((level) => DropdownMenuItem(
                          value: level,
                          child: Text("Level $level"),
                        )),
                  ],
                ),
              ],
            ),
          ),

          // 📄 Submissions List
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: submissionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No submissions found.", style: TextStyle(fontSize: 16)));
                }

                final submissions = snapshot.data!;

                return ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final data = submissions[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          data['studentName'] ?? 'Unnamed',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "Matric: ${data['studentId']} • Level: ${data['level']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => showSubmissionDetails(context, data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
