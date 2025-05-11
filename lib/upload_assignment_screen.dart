import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class UploadAssignmentScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? assignmentId;

  const UploadAssignmentScreen({super.key, this.existingData, this.assignmentId});

  @override
  State<UploadAssignmentScreen> createState() => _UploadAssignmentScreenState();
}

class _UploadAssignmentScreenState extends State<UploadAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final courseController = TextEditingController();

  final List<String> departmentsList = [
    "Computer Science", "Biochemistry", "Economics", "Accounting",
    "Political Science", "History", "Microbiology", "Geology",
    "Mass Communication", "Marketing", "Industrial Chemistry", "Finance", "IRPM"
  ];
  final List<String> levelsList = ['100', '200', '300', '400'];

  List<String> selectedDepartments = [];
  List<String> selectedLevels = [];
  DateTime? dueDate;
  File? pickedFile;
  bool isUploading = false;

  bool get isEditing => widget.existingData != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.existingData!;
      titleController.text = data['title'] ?? '';
      descriptionController.text = data['description'] ?? '';
      courseController.text = data['course'] ?? '';
      selectedDepartments = List<String>.from(data['departments'] ?? []);
      selectedLevels = List<String>.from(data['levels'] ?? []);
      dueDate = data['deadline']?.toDate();
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> submitAssignment() async {
    if (!_formKey.currentState!.validate() || dueDate == null || selectedDepartments.isEmpty || selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    setState(() => isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    final assignmentRef = widget.assignmentId != null
        ? FirebaseFirestore.instance.collection('assignments').doc(widget.assignmentId)
        : FirebaseFirestore.instance.collection('assignments').doc();

    String? fileUrl = widget.existingData?['fileUrl'];

    if (pickedFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref('assignments/${assignmentRef.id}/lecturer_uploads/${pickedFile!.path.split('/').last}');
      await storageRef.putFile(pickedFile!);
      fileUrl = await storageRef.getDownloadURL();
    }

    final assignmentData = {
      'assignmentId': assignmentRef.id,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'course': courseController.text.trim(),
      'departments': selectedDepartments,
      'levels': selectedLevels,
      'deadline': Timestamp.fromDate(dueDate!),
      'fileUrl': fileUrl,
      'uploadedBy': user!.uid,
      'uploadedAt': FieldValue.serverTimestamp(),
    };

    if (isEditing) {
      await assignmentRef.update(assignmentData);
    } else {
      await assignmentRef.set(assignmentData);

      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        if (selectedDepartments.contains(data['department']) && selectedLevels.contains(data['level'])) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': doc.id,
            'message': '${user.displayName ?? "A lecturer"} uploaded a new assignment: ${titleController.text.trim()}',
            'type': 'assignment',
            'target': 'student',
            'timestamp': FieldValue.serverTimestamp(),
            'level': data['level'],
            'department': data['department'],
          });
        }
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'message': 'You uploaded a new assignment.',
        'type': 'assignment',
        'target': 'lecturer',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    setState(() => isUploading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEditing ? "Assignment updated successfully" : "Assignment uploaded successfully")),
    );
  }

  InputDecoration customInputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontFamily: 'Kanit', fontWeight: FontWeight.w600),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF307DBA), width: 2),
      borderRadius: BorderRadius.circular(14),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5EBCE2), Color(0xFF307DBA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Edit Assignment' : 'Upload Assignment',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Kanit',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: customInputDecoration("Assignment Title"),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: customInputDecoration("Description"),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: courseController,
                            decoration: customInputDecoration("Course Code (e.g. CSC 301)"),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),
                          const Text("Select Departments", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Kanit')),
                          const SizedBox(height: 8),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: const Text("Select Department", style: TextStyle(fontFamily: 'Kanit', fontWeight: FontWeight.bold)),
                              items: departmentsList.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                              onChanged: (value) {
                                if (value != null && !selectedDepartments.contains(value)) {
                                  setState(() => selectedDepartments.add(value));
                                }
                              },
                              buttonStyleData: ButtonStyleData(
                                height: 55,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white,
                                ),
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            children: selectedDepartments.map((e) => Chip(
                              label: Text(e, style: const TextStyle(fontFamily: 'Kanit')),
                              onDeleted: () => setState(() => selectedDepartments.remove(e)),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text("Select Levels", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Kanit')),
                          const SizedBox(height: 8),
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: const Text("Select Level", style: TextStyle(fontFamily: 'Kanit', fontWeight: FontWeight.bold)),
                              items: levelsList.map((lvl) => DropdownMenuItem(value: lvl, child: Text('$lvl Level'))).toList(),
                              onChanged: (value) {
                                if (value != null && !selectedLevels.contains(value)) {
                                  setState(() => selectedLevels.add(value));
                                }
                              },
                              buttonStyleData: ButtonStyleData(
                                height: 55,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white,
                                ),
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            children: selectedLevels.map((e) => Chip(
                              label: Text('$e Level', style: const TextStyle(fontFamily: 'Kanit')),
                              onDeleted: () => setState(() => selectedLevels.remove(e)),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFFEBDA48)),
                              const SizedBox(width: 10),
                              Text(
                                dueDate != null ? "Due: ${dueDate!.toLocal().toString().split(' ')[0]}" : "No due date selected",
                                style: const TextStyle(fontFamily: 'Kanit', fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 3)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() => dueDate = picked);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF307DBA)),
                                child: const Text("Pick Date", style: TextStyle(fontFamily: 'Kanit', color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(
                              pickedFile == null ? "Attach Word File (Optional)" : "File Selected",
                              style: const TextStyle(fontFamily: 'Kanit'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black,
                              elevation: 1,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: ElevatedButton(
                              onPressed: submitAssignment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 62, 141, 205),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: Text(
                                isEditing ? "Update Assignment" : "Upload Assignment",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Kanit', color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}
