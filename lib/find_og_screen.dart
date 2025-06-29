import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_detail_screen.dart';

class FindOGScreen extends StatefulWidget {
  const FindOGScreen({super.key});

  @override
  State<FindOGScreen> createState() => _FindOGScreenState();
}

class _FindOGScreenState extends State<FindOGScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<DocumentSnapshot> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterGroups);
    _filterGroups(); // initial load
  }

  void _filterGroups() async {
    final query = _searchController.text.toLowerCase();

    final snap =
        await FirebaseFirestore.instance.collection('study_groups').get();

    final allGroups = snap.docs;

    final yourGroups = allGroups
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final members = List<String>.from(data['members'] ?? []);
          return members.contains(userId);
        })
        .map((doc) => doc.id)
        .toSet();

    setState(() {
      _filteredGroups = allGroups
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final members = List<String>.from(data['members'] ?? []);
            final name = data['name']?.toLowerCase() ?? '';
            if (name.isEmpty) return false; // 💡 Skip groups with no name

            final isInGroup =
                members.contains(userId) || yourGroups.contains(doc.id);
            final matchesQuery = name.contains(query);

            return !isInGroup && matchesQuery;
          })
          .take(5)
          .toList();
    });
  }

  void _createGroupPopup() {
    String groupName = '';
    String description = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Study Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Group Name'),
              onChanged: (val) => groupName = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (val) => description = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (groupName.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('study_groups').add({
                'name': groupName.trim(),
                'description': description.trim(),
                'creatorId': userId,
                'members': [userId],
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(ctx);
              _filterGroups();
              setState(() {}); // refresh UI
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5EBCE2),
        title: const Text(
          'Find a Study OG',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Kanit',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createGroupPopup,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for groups...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 🔹 YOUR GROUPS SECTION
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('study_groups')
                .where('members', arrayContains: userId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("You have not created or joined any group."),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Text(
                      "Your Groups",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...docs.map((group) {
                    final data = group.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          data['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Kanit',
                          ),
                        ),
                        subtitle: Text(data['description'] ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(
                                groupId: group.id,
                                groupData: data,
                                isCreator: userId == data['creatorId'],
                                isMember: true,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  })
                ],
              );
            },
          ),

          const SizedBox(height: 10),

          // 🔹 AVAILABLE GROUPS TO JOIN
Expanded(
  child: (_filteredGroups.isEmpty && _searchController.text.isNotEmpty)
      ? const Center(child: Text("No groups found."))
      : ListView.builder(
          itemCount: _filteredGroups.length,
          itemBuilder: (context, index) {
            final group = _filteredGroups[index];
            final data = group.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                title: Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Kanit',
                  ),
                ),
                subtitle: Text(data['description'] ?? ''),
                trailing: TextButton(
                  child: const Text("Join"),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('study_groups')
                        .doc(group.id)
                        .update({
                      'members': FieldValue.arrayUnion([userId])
                    });
                    _filterGroups();
                    setState(() {});
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(
                        groupId: group.id,
                        groupData: data,
                        isCreator: userId == data['creatorId'],
                        isMember: false,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
),
        ],
      ),
    );
  }
}
