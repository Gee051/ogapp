import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;
  final bool isCreator;
  final bool isMember;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupData,
    required this.isCreator,
    required this.isMember,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  bool isLoading = false;

  Future<void> leaveGroup() async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('study_groups').doc(widget.groupId).update({
        'members': FieldValue.arrayRemove([user.uid]),
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error leaving group: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> confirmRemoveMember(String memberId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      await removeMember(memberId);
    }
  }

  Future<void> removeMember(String memberId) async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('study_groups').doc(widget.groupId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing member: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = widget.groupData['name'] ?? 'Group';
    final groupDesc = widget.groupData['description'] ?? 'No description';
    final creatorId = widget.groupData['createdBy']; // ✅ corrected

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5EBCE2),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          groupName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Kanit',
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📘 Group Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(groupDesc),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    "👥 Members",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('study_groups')
                          .doc(widget.groupId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        final List members = data['members'] ?? [];

                        if (members.isEmpty) {
                          return const Text("No members yet.");
                        }

                        return ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final memberId = members[index];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(memberId).get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) return const SizedBox();

                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                if (userData == null) return const SizedBox();

                                final name = userData['name'] ??
                                    userData['studentName'] ??
                                    userData['fullName'] ??
                                    'Unnamed';
                                final level = userData['level'] ?? '';
                                final dept = userData['department'] ?? '';

                                final isGroupCreator = memberId == creatorId;
                                final isSelf = memberId == user.uid;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (isGroupCreator)
                                          const Icon(Icons.verified, color: Colors.blue, size: 25),
                                      ],
                                    ),
                                    subtitle: Text('$level • $dept'),
                                    trailing: (creatorId == user.uid && !isSelf)
                                        ? IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () => confirmRemoveMember(memberId),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (widget.isMember && !widget.isCreator)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: leaveGroup,
                        icon: const Icon(Icons.logout),
                        label: const Text("Leave Group"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
