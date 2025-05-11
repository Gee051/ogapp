import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event_details_screen.dart';
// import 'events_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userFirstName;
  final VoidCallback? onSeeMoreTapped; // ✅ Add this line

  const HomeScreen({
    super.key,
    required this.userFirstName,
    this.onSeeMoreTapped, // ✅ Include it in the constructor
  });


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userFirstName = '';
  String userRole = '';
  List<Map<String, dynamic>> randomEvents = [];

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchRandomEvents();
  }

  Future<void> fetchUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final fullName = doc.data()?['fullName'] ?? '';
      final role = doc.data()?['role'] ?? '';
      setState(() {
        userFirstName = fullName.split(' ').first;
        userRole = role;
      });
    }
  }

  Future<void> fetchRandomEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    final allEvents = snapshot.docs.map((doc) => doc.data()).toList();
    allEvents.shuffle(Random());
    setState(() {
      randomEvents = allEvents.take(3).toList();
    });
  }

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF307DBA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_fire_department, color: Colors.orange),
                title: const Text(
                  'Learning Streaks: 5',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Read for at least 15 minutes to maintain your streak. Missing activity for 48 hours will reset it.',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white70),
              SwitchListTile(
                title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
                value: false,
                onChanged: (val) {},
              ),
            ],
          ),
        );
      },
    );
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
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $userFirstName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {}, // Add action
                  ),
                  Positioned(
                    right: 11,
                    top: 3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        ' ',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _showMenu,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟦 Motivational Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF307DBA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "OG -- Your number 1 school guy! 💪",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),

            const SizedBox(height: 24),
            sectionTitle("Recent News"),
            const SizedBox(height: 10),

            SizedBox(
              height: 150,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('news').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final newsList = snapshot.data!.docs;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final news = newsList[index].data() as Map<String, dynamic>;
                      return NewsCard(
                        imageUrl: news['image'],
                        text: news['text'],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sectionTitle("Memory Verse"),
                const Text("For the week", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5EBCE2), Color(0xFF307DBA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '"For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end." – Jeremiah 29:11',
                style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sectionTitle("Events"),
                
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: randomEvents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: randomEvents.length,
                      itemBuilder: (context, index) {
                        final event = randomEvents[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                            );
                          },
                          child: LibraryCard(
                            imageUrl: event['image'],
                            label: event['name'],
                            description: event['date'],
                          ),
                        );
                      },
                    ),
            ),
            TextButton(
                 onPressed: widget.onSeeMoreTapped,

                  child: const Text("See More", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),

            const SizedBox(height: 24),
            sectionTitle("Helpful Links"),
            const SizedBox(height: 10),
            Column(
              children: [
                ActivityCard(
                  description: 'Visit Crawford Website',
                  onTap: () => _launchURL('https://crawforduniversity.edu.ng/crawford/index.php'),
                ),
                ActivityCard(
                  description: 'Visit Crawford Portal',
                  onTap: () => _launchURL('https://portal.crawforduniversity.edu.ng'),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Kanit',
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        ),
      );
}

// 🔸 NewsCard
class NewsCard extends StatelessWidget {
  final String imageUrl;
  final String text;

  const NewsCard({super.key, required this.imageUrl, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// 🔹 Events
class LibraryCard extends StatelessWidget {
  final String imageUrl;
  final String label;
  final String description;

  const LibraryCard({super.key, required this.imageUrl, required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔗 Helpful Links
class ActivityCard extends StatelessWidget {
  final String description;
  final VoidCallback? onTap;

  const ActivityCard({super.key, required this.description, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.link, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }
}
