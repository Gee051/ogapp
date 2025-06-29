import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'upload_file.dart';

class SchoolScreen extends StatefulWidget {
  @override
  _SchoolScreenState createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  String? role;
  String department = "";
  bool isAdmin = false;
  Set<String> savedNoteIds = {};

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    fetchSavedNotes();
  }

  Future<void> fetchUserDetails() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = doc.data() ?? {};

    setState(() {
      role = userData['role'];
      department = userData['department'] ?? '';
      isAdmin = userData['isAdmin'] == true;
    });
  }

  Future<void> fetchSavedNotes() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snapshots = await FirebaseFirestore.instance
        .collection('saved_notes')
        .where('studentId', isEqualTo: userId)
        .get();
    setState(() {
      savedNoteIds =
          snapshots.docs.map((doc) => doc['noteId'] as String).toSet();
    });
  }

  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);
      final result = await OpenFilex.open(file.path);
      print("📂 File opened: ${result.message}");
    } catch (e) {
      print("❌ Failed to open file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open the file.")),
      );
    }
  }

  Widget buildFileList(String collectionName, String label) {
    if (department.isEmpty) return SizedBox();

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .where('department', isEqualTo: department)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              collectionName == 'materials'
                  ? "No lecturer materials uploaded yet."
                  : "No past questions uploaded yet.",
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Kanit',
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final noteId = docs[index].id;
                final isSaved = savedNoteIds.contains(noteId);
                final fileUrl = data['fileUrl'];
                final title = data['title'] ?? 'file';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        data['courseCode'] ?? '',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      trailing: role == 'lecturer'
                          ? null
                          : Icon(
                              isSaved
                                  ? Icons.bookmark_added
                                  : Icons.bookmark_border,
                              color: isSaved ? Colors.green : null,
                            ),
                      onTap: () async {
                        final ext = Uri.parse(fileUrl)
                            .path
                            .split('.')
                            .last
                            .toLowerCase();
                        final safeName = title.replaceAll(' ', '_') + '.$ext';

                        final isDocument = [
                          'pdf',
                          'doc',
                          'docx',
                          'ppt',
                          'pptx',
                          'xls',
                          'xlsx'
                        ].contains(ext);
                        final isImage =
                            ['jpg', 'jpeg', 'png', 'webp'].contains(ext);

                        if (isDocument) {
                          downloadAndOpenFile(fileUrl, safeName);
                        } else if (isImage) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(fileUrl),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text("Download"),
                                    onPressed: () async {
                                      try {
                                        final response =
                                            await http.get(Uri.parse(fileUrl));
                                        final dir =
                                            await getTemporaryDirectory();
                                        final file =
                                            File('${dir.path}/$safeName');
                                        await file
                                            .writeAsBytes(response.bodyBytes);
                                        final result =
                                            await OpenFilex.open(file.path);
                                        print(
                                            "✅ Image downloaded: ${result.message}");
                                      } catch (e) {
                                        print("❌ Image download failed: $e");
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Failed to download image.")),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: const Text("Close"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Unsupported file format.")),
                          );
                        }
                      }),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
    ? Colors.black
    : const Color(0xFFF8FAFF),

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
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Academic Resources',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFileList('materials', 'Lecturer Materials'),
            const SizedBox(height: 30),
            if (role == 'student')
              buildFileList('past_questions', 'Past Questions'),
          ],
        ),
      ),
      floatingActionButton:
          (role == 'lecturer' || (role == 'student' && isAdmin))
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadFile(
                          role: role!,
                          department: department,
                        ),
                      ),
                    );
                    if (result == 'uploaded') {
                      fetchUserDetails(); // Refresh on return
                    }
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text(
                    "Upload",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueAccent,
                )
              : null,
    );
  }
}
