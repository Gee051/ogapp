import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> assignmentData;

  const AssignmentDetailScreen({super.key, required this.assignmentData});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool isLoading = true;
  bool deadlinePassed = false;
  String? userRole;

  @override
  void initState() {
    super.initState();
    getUserRoleAndCheckSubmission();
  }

  Future<void> getUserRoleAndCheckSubmission() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final assignmentId = widget.assignmentData['id'];

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      userRole = userDoc.data()?['role'];

      final deadline = widget.assignmentData['deadline']?.toDate();
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        deadlinePassed = true;
      }

      if (userRole == 'student') {
        final matricNumber = userDoc.data()?['matricNumber'];
        final submissionSnap = await FirebaseFirestore.instance
            .collection('assignment_submissions')
            .where('assignmentId', isEqualTo: assignmentId)
            .where('studentId', isEqualTo: matricNumber)
            .limit(1)
            .get();

        hasSubmitted = submissionSnap.docs.isNotEmpty;
      }
    } catch (e) {
      print("❌ Error checking submission: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> showSubmissionDialog() async {
    final TextEditingController textController = TextEditingController();
    File? selectedFile;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Drop Text (Optional)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx'],
                  );
                  if (result != null &&
                      result.files.single.size <= 10 * 1024 * 1024) {
                    setState(() {
                      selectedFile = File(result.files.single.path!);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('File too large or unsupported')),
                    );
                  }
                },
                child: Text(selectedFile == null
                    ? 'Attach File (Optional)'
                    : 'File Selected'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await handleSubmission(textController.text, selectedFile);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> handleSubmission(String answerText, File? file) async {
    setState(() => isSubmitting = true);

    final assignmentId = widget.assignmentData['id'];
    final course = widget.assignmentData['course'];
    final department = widget.assignmentData['departments'][0];
    final level = widget.assignmentData['levels'][0];
    final deadline = widget.assignmentData['deadline'].toDate();
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser!;

    if (now.isAfter(deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline has passed')),
      );
      setState(() => isSubmitting = false);
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data()!;
    final studentName = userData['fullName'] ?? 'Unnamed Student';
    final matricNumber = userData['matricNumber'] ?? 'Unknown';

    String? uploadedFileUrl;
    if (file != null) {
      final fileName = '${matricNumber}_${file.path.split('/').last}';
      final storageRef = FirebaseStorage.instance
          .ref('assignment_submissions/$assignmentId/$fileName');
      await storageRef.putFile(file);
      uploadedFileUrl = await storageRef.getDownloadURL();
    }

    final submissionPayload = {
      'assignmentId': assignmentId,
      'course': course,
      'department': department,
      'level': level,
      'fileUrl': uploadedFileUrl ?? '',
      'studentId': matricNumber,
      'studentName': studentName,
      'submissionId': '${assignmentId}_${matricNumber}',
      'submittedAt': Timestamp.now(),
      'textAnswer': answerText.trim().isNotEmpty ? answerText : null,
    };

    try {
      await FirebaseFirestore.instance
          .collection('assignment_submissions')
          .add(submissionPayload);

      setState(() => isSubmitting = false);
      await getUserRoleAndCheckSubmission(); // Re-check to hide the submit button

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted successfully')),
      );
    } catch (e) {
      print("❌ Firestore submission failed: $e");
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.assignmentData;
    final title = data['title'] ?? '';
    final course = data['course'] ?? '';
    final description = data['description'] ?? '';
    final departments = List<String>.from(data['departments'] ?? []);
    final levels = List<String>.from(data['levels'] ?? []);
    final dueDate = data['deadline']?.toDate();
    final fileUrl = data['fileUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF307DBA),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Course: $course', style: const TextStyle(fontSize: 18)),
            Text(
                'Due Date: ${dueDate?.toLocal().toString().split(' ')[0] ?? ''}',
                style: const TextStyle(fontSize: 18)),
            Text('Departments: ${departments.join(', ')}',
                style: const TextStyle(fontSize: 18)),
            Text('Levels: ${levels.join(', ')}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('Description:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (fileUrl != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF307DBA)),
                onPressed: () async {
                  final uri = Uri.parse(fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open file')),
                    );
                  }
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Download File',
                    style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 30),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (userRole == 'student') ...[
              if (hasSubmitted)
                const Text(
                  'You have already submitted this assignment.',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                )
              else if (deadlinePassed)
                const Text(
                  'Deadline has passed. You can no longer submit.',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                )
              else
                ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSubmitting ? null : showSubmissionDialog,
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text('Submit Assignment',
                      style: TextStyle(color: Colors.white, fontSize: 19)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
