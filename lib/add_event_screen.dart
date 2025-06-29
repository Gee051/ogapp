import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  String? imageUrl;
  bool isUploading = false;

  Future<void> pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('event_images/$fileName');

    setState(() => isUploading = true);
    await ref.putFile(file);
    imageUrl = await ref.getDownloadURL();
    setState(() => isUploading = false);
  }

  Future<void> saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'name': nameController.text.trim(),
      'date': dateController.text.trim(),
      'description': descriptionController.text.trim(),
      'location': locationController.text.trim(),
      'image': imageUrl,
      'uploadedAt': Timestamp.now(),
    });

    Navigator.pop(context, 'added');
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
              'Add New Event',
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildInputField(nameController, 'Event Name'),
              const SizedBox(height: 14),
              buildInputField(dateController, 'Date (e.g., June 2, 2025)'),
              const SizedBox(height: 14),
              buildInputField(locationController, 'Location'),
              const SizedBox(height: 14),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(fontSize: 16),
                decoration: buildInputDecoration('Description'),
                validator: (val) => val!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 20),
              isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: pickAndUploadImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.image, color: Colors.white),
                      label: Text(
                        imageUrl != null ? 'Change Image' : 'Upload Image',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Event',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField buildInputField(
      TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: buildInputDecoration(labelText),
      validator: (val) => val!.isEmpty ? 'Required field' : null,
    );
  }

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),

      ),
    );
  }
}
