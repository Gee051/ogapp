import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF5EBCE2), // Light blue background
      resizeToAvoidBottomInset: true, // ✅ Prevent overflow on keyboard
      body: SafeArea(
        child: SingleChildScrollView( // ✅ Prevent layout crash
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Logo on top-left
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 16.0),
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 50,
                    ),
                  ),

                  // 🔹 Centered og.png image
                  Center(
                    child: Hero(
                      tag: 'hero-image',
                      child: Image.asset(
                        'assets/images/og.png',
                        height: screenSize.height * 0.42,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔹 Wrapped Welcome Text with "OG" in deep blue
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        children: [
                          const TextSpan(
                            text: "Welcome to",
                            style: TextStyle(color: Color(0xFFF2F2F2)),
                          ),
                          TextSpan(
                            text: " OG",
                            style: TextStyle(
                              color: Color(0xFF307DBA),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔹 Subtitle with yellow "study guy"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(text: "Your "),
                          TextSpan(
                            text: "study guy!",
                            style: TextStyle(color: Color(0xFFEBDA48), fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔹 Login Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // ✅ hide keyboard if still up
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBDA48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🔹 Sign Up Button (Transparent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // ✅ hide keyboard if still up
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0x00452F1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
