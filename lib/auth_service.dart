import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up Method (Students & Lecturers)
  Future<User?> signUpWithEmail({
    required String fullName,
    required String department,
    required String email,
    required String password,
    required String role, // "student" or "lecturer"
    String? level, // Only for students
    String? matricNumber, // Only for students
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "fullName": fullName,
        "email": email,
        "department": department,
        "role": role,
        if (role == "student") "level": level, // Store level only if student
        if (role == "student") "matricNumber": matricNumber, // Store matric number only if student
      });

      return userCredential.user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // Login Method
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Get User Role
  Future<String?> getUserRole(String userId) async {
    DocumentSnapshot doc = await _firestore.collection("users").doc(userId).get();
    return doc.exists ? doc["role"] : null;
  }

  // Sign Out Method
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
