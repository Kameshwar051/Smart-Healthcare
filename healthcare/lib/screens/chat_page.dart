import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String receiverId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String senderId = _auth.currentUser!.uid;
    String messageText = _messageController.text.trim();

    // Save message to Firestore
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'messageType': 'text',
      'status': 'sent',
    });

    // Update lastUpdated timestamp
    await _firestore.collection('chats').doc(widget.chatId).update({
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(widget.receiverName),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Start from bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSender =
                        message['senderId'] == _auth.currentUser!.uid;

                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSender
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'],
                              style: TextStyle(
                                  color:
                                      isSender ? Colors.white : Colors.black),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                _formatTimestamp(message['timestamp']),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Function to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.hour}:${dateTime.minute}";
  }
}
