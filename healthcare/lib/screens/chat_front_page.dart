import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatFrontPage extends StatefulWidget {
  const ChatFrontPage({super.key});

  @override
  State<ChatFrontPage> createState() => _ChatFrontPageState();
}

class _ChatFrontPageState extends State<ChatFrontPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),

          // Display Recent Chats OR Search Results
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildRecentChats()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  // Build Recent Chats (Sorted by lastUpdated)
  Widget _buildRecentChats() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastUpdated', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Search and chat with users to get started",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        var chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];

            if (!chat.exists ||
                !chat.data().toString().contains('participants')) {
              return const SizedBox(); // Skip if field doesn't exist
            }

            var participants = List.from(chat['participants']);
            String otherUserId = participants
                .firstWhere((id) => id != currentUserId, orElse: () => "");

            if (otherUserId.isEmpty) return const SizedBox();

            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox();
                }

                var user = userSnapshot.data!;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(user['name'][0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Tap to continue chat"),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/chat_page',
                      arguments: {
                        'chatId': chat.id,
                        'receiverName': user['name'],
                        'receiverId': user['uid'].toString(),
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Build Search Results (Only Show Users Who Haven't Been Messaged Yet)
  Widget _buildSearchResults() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThan: _searchQuery + 'z')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No users found",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        var users = snapshot.data!.docs;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Text(user['name'][0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(user['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user['email']),
              onTap: () async {
                String chatId = await _createNewChat(user['uid'].toString());

                Navigator.pushNamed(
                  context,
                  '/chat_page',
                  arguments: {
                    'chatId': chatId,
                    'receiverName': user['name'],
                    'receiverId': user['uid'].toString(),
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Create a new chat if not exists
  Future<String> _createNewChat(String receiverId) async {
    var chatRef = FirebaseFirestore.instance.collection('chats');

    var existingChat =
        await chatRef.where('participants', arrayContains: currentUserId).get();

    for (var doc in existingChat.docs) {
      var participants = List.from(doc['participants']);
      if (participants.contains(receiverId)) {
        return doc.id; // Chat already exists, return chat ID
      }
    }

    // Create new chat
    var newChat = await chatRef.add({
      'participants': [currentUserId, receiverId],
      'lastUpdated': FieldValue.serverTimestamp(),
      'messages': [],
    });

    return newChat.id; // Return new chat ID
  }
}
