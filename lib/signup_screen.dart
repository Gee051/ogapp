import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'auth_service.dart';
import 'login_screen.dart';

final List<String> departments = [
  "Computer Science",
  "Biochemistry",
  "Economics",
  "Accounting",
  "Political Science",
  "History",
  "Microbiology",
  "Geology",
  "Mass Communication",
  "Marketing",
  "Industrial Chemistry",
  "Finance",
  "IRPM"
];

final List<String> levels = ["100L", "200L", "300L", "400L"];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final matricNumberController = TextEditingController();

  final AuthService _authService = AuthService();

  String role = "";
  String? selectedDepartment;
  String? selectedLevel;

  String? _emailError;
  String? _emailExistError;
  String? _passwordError;
  String? _fullNameError;
  String? _matricError;

  bool _obscurePassword = true;

  void _signUp() async {
    setState(() {
      _emailError = null;
      _emailExistError = null;
      _passwordError = null;
      _fullNameError = null;
      _matricError = null;
    });

    if (fullNameController.text.trim().isEmpty) {
      setState(() => _fullNameError = "This field must not be empty");
      return;
    }

    if (emailController.text.trim().isEmpty) {
      setState(() => _emailError = "This field must not be empty");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      setState(() => _emailError = 'Please enter a valid email');
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }

    if (selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a department.")),
      );
      return;
    }

    if (role == "student" && selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a level.")),
      );
      return;
    }

    if (role == "student" && matricNumberController.text.trim().isEmpty) {
      setState(() => _matricError = "This field must not be empty");
      return;
    }

    try {
      User? user = await _authService.signUpWithEmail(
        fullName: fullNameController.text.trim(),
        department: selectedDepartment!,
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        role: role,
        level: role == "student" ? selectedLevel : null,
        matricNumber:
            role == "student" ? matricNumberController.text.trim() : null,
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign up successful! Please log in.")),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        });
      } else {
        setState(() {
          _emailExistError = "Email already exists";
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailExistError = "Email already exists";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign Up Failed. Try again!")),
        );
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
    bool obscure = false,
    Widget? suffixIcon,
    TextStyle? style, 
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: style ?? const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: const TextStyle( 
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5EBCE2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF307DBA))),
              const SizedBox(height: 4),
              const Text("Have a study OG",
                  style: TextStyle(
                      fontSize: 19,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: Row(
                    children: const [
                      Icon(Icons.person_outline, color: Colors.black),
                      SizedBox(width: 10),
                      Text("Select Role",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ],
                  ),
                  value: role.isEmpty ? null : role,
                  items: ["student", "lecturer"].map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      role = value!;
                      selectedLevel = null;
                    });
                  },
                  buttonStyleData: ButtonStyleData(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  iconStyleData: const IconStyleData(
                    icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    offset: const Offset(0, 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Full Name
              buildTextField(
                controller: fullNameController,
                hint: "Full Name",
                icon: Icons.person,
                style: const TextStyle(fontSize: 20),
                
              ),
              if (_fullNameError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: Text(
                    _fullNameError!,
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),

              const SizedBox(height: 12),

              // Email
              buildTextField(
                controller: emailController,
                hint: "Email",
                icon: Icons.email,
                style: const TextStyle(fontSize: 20),
              ),
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: Text(
                    _emailError!,
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              if (_emailExistError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: Text(
                    _emailExistError!,
                    style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),

              const SizedBox(height: 12),

              // Password
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                  hintText: "Password",
                  hintStyle: const TextStyle(fontWeight: FontWeight.bold),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.black),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (_passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: Text(
                    _passwordError!,
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              const SizedBox(height: 12),

              // Department Dropdown
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: Row(
                    children: const [
                      Icon(Icons.apartment, color: Colors.black),
                      SizedBox(width: 10),
                      Text("Select Department",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ],
                  ),
                  value: selectedDepartment,
                  items: departments.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value!;
                    });
                  },
                  buttonStyleData: ButtonStyleData(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  iconStyleData: const IconStyleData(
                    icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    offset: const Offset(0, 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (role == "student") ...[
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: Row(
                      children: const [
                        Icon(Icons.school, color: Colors.black),
                        SizedBox(width: 10),
                        Text("Select Level",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ],
                    ),
                    value: selectedLevel,
                    items: levels.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLevel = value!;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      offset: const Offset(0, 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Matric Number
                buildTextField(
                  controller: matricNumberController,
                  hint: "Matric Number",
                  icon: Icons.badge,
                  style: const TextStyle(fontSize: 18),
                ),
                if (_matricError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 4),
                    child: Text(
                      _matricError!,
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
              ],
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBDA48),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      children: [
                        TextSpan(text: "Already have an account? "),
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
