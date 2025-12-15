import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'user_mini_profile.dart';


class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Cached user data
  String myName = "Unknown";
  String myProfileImage = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      myName = data["name"] ?? "Unknown";
      myProfileImage = data["profileImageUrl"] ?? "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Send message
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection("messages")
        .doc("global_chat")
        .collection("msgs")
        .add({
      "senderId": user!.uid,
      "senderName": myName,
      "profileImageUrl": myProfileImage,
      "text": _controller.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
    });

    _controller.clear();

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Edit message
  Future<void> _editMessage(String messageId, String oldText) async {
    final editController = TextEditingController(text: oldText);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Message"),
        content: TextField(controller: editController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("messages")
                  .doc("global_chat")
                  .collection("msgs")
                  .doc(messageId)
                  .update({
                "text": editController.text.trim(),
                "edited": true,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Delete message
  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection("messages")
        .doc("global_chat")
        .collection("msgs")
        .doc(messageId)
        .delete();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "";
    return DateFormat('hh:mm a').format(ts.toDate());
  }

  // Avatar widget
  Widget _buildAvatar(String image, String name, String senderId) {
    return GestureDetector(
      onTap: senderId == user!.uid
          ? null
          : () => _openUserProfile(senderId),
      child: CircleAvatar(
        radius: 16,
        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
        child: image.isEmpty ? Text(name[0].toUpperCase()) : null,
      ),
    );
  }

  // Open mini profile
  void _openUserProfile(String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UserMiniProfile(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Global Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .doc("global_chat")
                  .collection("msgs")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final isMe = data["senderId"] == user!.uid;

                    return GestureDetector(
                      onLongPress: isMe
                          ? () => showModalBottomSheet(
                                context: context,
                                builder: (_) => Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text("Edit"),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _editMessage(
                                            docs[index].id, data["text"]);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.delete),
                                      title: const Text("Delete"),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _deleteMessage(docs[index].id);
                                      },
                                    ),
                                  ],
                                ),
                              )
                          : null,
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            _buildAvatar(
                              data["profileImageUrl"] ?? "",
                              data["senderName"],
                              data["senderId"],
                            ),
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue.shade200
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      data["senderName"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  Text(data["text"]),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTimestamp(data["timestamp"]),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe)
                            _buildAvatar(
                              myProfileImage,
                              myName,
                              user!.uid,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input field
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "Type a message"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
