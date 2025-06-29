import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class UploadFile extends StatefulWidget {
  final String role;
  final String department;

  const UploadFile({required this.role, required this.department});

  @override
  State<UploadFile> createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile> {
  final titleController = TextEditingController();
  final courseCodeController = TextEditingController();
  bool isUploading = false;
  bool isCourseRep = false;
  String? lastDownloadUrl;
  String? lastFileTitle;

  @override
  void initState() {
    super.initState();
    determineIfCourseRep();
  }

  Future<void> determineIfCourseRep() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data() ?? {};

    if (!mounted) return;
    setState(() {
      isCourseRep = widget.role == 'student' && data['isAdmin'] == true;
    });
  }

  Future<void> openFile(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open file.")),
      );
    }
  }

  Future<void> saveNote(String url, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('saved_notes').add({
      'studentId': user.uid,
      'fileUrl': url,
      'title': title,
      'savedAt': Timestamp.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note saved successfully!")),
    );
  }

  Future<void> handleUpload() async {
    final courseCode = courseCodeController.text.trim();
    final title = titleController.text.trim();

    if (courseCode.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both title and course code.")),
      );
      return;
    }

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission is required.")),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result == null) return;

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;

    if (file.lengthSync() > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File is too large. Max 10MB allowed.")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isUploading = true);

    final folder = isCourseRep ? 'past_questions' : 'materials';
    final collection = folder;

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final sanitizedDept = widget.department.replaceAll(' ', '_');
      final sanitizedCourseCode = courseCode.replaceAll(' ', '_');

      final storagePath = "$folder/$sanitizedDept/$sanitizedCourseCode/$fileName";
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection(collection).add({
        "title": title,
        "department": widget.department,
        "courseCode": courseCode,
        "fileUrl": downloadUrl,
        "uploadedBy": userId,
        "uploadedAt": Timestamp.now(),
      });

      if (!mounted) return;
      setState(() {
        lastDownloadUrl = downloadUrl;
        lastFileTitle = title;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload successful! Opening file...")),
      );

      await openFile(downloadUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLecturer = widget.role == 'lecturer';
    final screenTitle = isLecturer
        ? "Upload Lecturer Material"
        : isCourseRep
            ? "Upload Past Question"
            : "Upload File";

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
              screenTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "File Title"),
            ),
            TextField(
              controller: courseCodeController,
              decoration: const InputDecoration(labelText: "Course Code (e.g. CSC 301)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isUploading ? null : handleUpload,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Select & Upload File", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
            if (lastDownloadUrl != null) ...[
              const SizedBox(height: 30),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.green),
                title: Text(lastFileTitle ?? 'Uploaded File'),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, color: Colors.deepOrange),
                  onPressed: () => saveNote(lastDownloadUrl!, lastFileTitle ?? ''),
                ),
                onTap: () => openFile(lastDownloadUrl!),
              )
            ],
          ],
        ),
      ),
    );
  }
}
