import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class SavedNotesScreen extends StatefulWidget {
  @override
  _SavedNotesScreenState createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  Set<String> savedNoteIds = {};
  List<Map<String, dynamic>> allNotes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSavedNotes();
  }

  Future<void> fetchSavedNotes() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      final savedSnap = await FirebaseFirestore.instance
          .collection('saved_notes')
          .where('studentId', isEqualTo: userId)
          .get();

      final noteIds = savedSnap.docs
          .map((doc) => doc.data()['noteId'])
          .whereType<String>()
          .toSet();

      List<Map<String, dynamic>> notes = [];

      for (final id in noteIds) {
        final materialDoc = await FirebaseFirestore.instance
            .collection('materials')
            .doc(id)
            .get();
        if (materialDoc.exists) {
          notes.add({...materialDoc.data()!, 'id': id, 'type': 'material'});
          continue;
        }

        final pqDoc = await FirebaseFirestore.instance
            .collection('past_questions')
            .doc(id)
            .get();
        if (pqDoc.exists) {
          notes.add({...pqDoc.data()!, 'id': id, 'type': 'past_question'});
        }
      }

      setState(() {
        savedNoteIds = noteIds;
        allNotes = notes;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching saved notes: $e');
      setState(() => isLoading = false);
    }
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

  Future<void> unsaveNote(String noteId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('saved_notes')
        .where('noteId', isEqualTo: noteId)
        .where('studentId', isEqualTo: userId)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }

    fetchSavedNotes();
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
              'Saved Notes',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allNotes.isEmpty
              ? const Center(
                  child: Text('No saved notes yet.',
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: allNotes.length,
                  itemBuilder: (context, index) {
                    final note = allNotes[index];
                    final fileUrl = note['fileUrl'];
                    final title = note['title'] ?? 'file';
                    final uri = Uri.parse(fileUrl);
                    final fileName = uri.pathSegments.last.split('?').first;
                    final ext = fileName.split('.').last.toLowerCase();

                    final safeName = title.replaceAll(' ', '_') + '.$ext';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(note['courseCode'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_remove,
                              color: Colors.red),
                          onPressed: () => unsaveNote(note['id']),
                        ),
                        onTap: () async {
                          final isDoc = [
                            'pdf',
                            'doc',
                            'docx',
                            'ppt',
                            'pptx',
                            'xls',
                            'xlsx'
                          ].contains(ext);
                          final isImage = ['jpg', 'jpeg', 'png'].contains(ext);

                          if (isDoc) {
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
                                          final response = await http
                                              .get(Uri.parse(fileUrl));
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
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "Failed to download image.")));
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
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
