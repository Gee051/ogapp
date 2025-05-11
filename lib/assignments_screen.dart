import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'upload_assignment_screen.dart';
import 'assignment_detail_screen.dart';

class AssignmentScreen extends StatelessWidget {
  final String userRole;
  final String userDepartment;
  final String userLevel;
  final String currentUserId;

  const AssignmentScreen({
    super.key,
    required this.userRole,
    required this.userDepartment,
    required this.userLevel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final userIsLecturer = userRole.toLowerCase() == 'lecturer';

    return Scaffold(
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
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Assignments',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Kanit',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('deadline', isGreaterThan: Timestamp.now())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allDocs = snapshot.data?.docs ?? [];

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (userIsLecturer) {
              return data['uploadedBy'] == currentUserId;
            } else {
              final departments = List<String>.from(data['departments'] ?? []);
              final levels = List<String>.from(data['levels'] ?? []);
              return departments.contains(userDepartment) && levels.contains(userLevel);
            }
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
              child: Text(
                'No available assignments at this time',
                style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? '';
              final course = data['course'] ?? '';
              final deadline = (data['deadline'] as Timestamp).toDate();

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Kanit',
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Course: $course',
                        style: const TextStyle(
                            fontFamily: 'Kanit', fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Due: ${deadline.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontFamily: 'Kanit'),
                      ),
                    ],
                  ),
                  trailing: userIsLecturer
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF307DBA)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadAssignmentScreen(
                                      assignmentId: doc.id,
                                      existingData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, doc.id, title),
                            ),
                          ],
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignmentDetailScreen(assignmentData: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: userIsLecturer
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF307DBA),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UploadAssignmentScreen(),
                  ),
                );
              },
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }

  void _confirmDelete(BuildContext context, String assignmentId, String assignmentTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "$assignmentTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('assignments').doc(assignmentId).delete();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
