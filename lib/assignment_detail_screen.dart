import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assignmentData;

  const AssignmentDetailScreen({super.key, required this.assignmentData});

  @override
  Widget build(BuildContext context) {
    final title = assignmentData['title'] ?? '';
    final course = assignmentData['course'] ?? '';
    final description = assignmentData['description'] ?? '';
    final departments = List<String>.from(assignmentData['departments'] ?? []);
    final levels = List<String>.from(assignmentData['levels'] ?? []);
    final dueDate = assignmentData['deadline']?.toDate();
    final fileUrl = assignmentData['fileUrl'];

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
              'Assignment Details',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Kanit',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Kanit'),
            ),
            const SizedBox(height: 10),
            Text('Course: $course', style: const TextStyle(fontSize: 18, fontFamily: 'Kanit')),
            const SizedBox(height: 10),
            Text('Due Date: ${dueDate?.toLocal().toString().split(' ')[0] ?? ''}', style: const TextStyle(fontSize: 18, fontFamily: 'Kanit')),
            const SizedBox(height: 10),
            Text('Departments: ${departments.join(', ')}', style: const TextStyle(fontSize: 18, fontFamily: 'Kanit')),
            const SizedBox(height: 10),
            Text('Levels: ${levels.join(', ')} Level', style: const TextStyle(fontSize: 18, fontFamily: 'Kanit')),
            const SizedBox(height: 20),
            const Text('Description:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Kanit')),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16, fontFamily: 'Kanit')),
            const SizedBox(height: 20),
            if (fileUrl != null) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF307DBA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () async {
                  final Uri uri = Uri.parse(fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open file')),
                    );
                  }
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Download Attached File', style: TextStyle(color: Colors.white, fontFamily: 'Kanit')),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
