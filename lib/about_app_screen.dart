import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "About App",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'Kanit',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "OG: Your Campus Companion",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'Kanit',
              color: Color(0xFF307DBA),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "OG app is an all-in-one academic and student life manager tailored to make campus life easier and more productive. Your personal school OG!!",
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: Colors.black87, 
            ),
          ),
          const SizedBox(height: 20),
          const Divider(thickness: 1.2),
          const SizedBox(height: 14),
          const Text(
            "As an OG, you can",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          _buildBulletPoint("📅 View and manage ", "class timetables."),
          _buildBulletPoint("📂 Access ", "course notes and past questions."),
          _buildBulletPoint("📝 Submit ", "assignments to your lecturers."),
          _buildBulletPoint(
              "🔔 Stay informed ", "with announcements and events."),
          _buildBulletPoint("🤝 Connect ", "with fellow OGs (Study groups)."),
          _buildBulletPoint("🧠 Track ", "your learning streaks."),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: const [
                Icon(Icons.school_rounded, size: 60, color: Color(0xFF307DBA)),
                SizedBox(height: 15),
                Text(
                  "Built with ❤️ for every OG.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF307DBA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String boldPart, String normalPart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontSize: 15)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 16, height: 1.5, color: Colors.black87),
                children: [
                  TextSpan(
                    text: boldPart,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: normalPart),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
