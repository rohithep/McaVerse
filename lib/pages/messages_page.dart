import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Send message to Firestore
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    // Get user document from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        .get();

    String senderName = "Unknown";
    String profileImageUrl = "";

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      senderName =
          data["name"] ?? "Unknown"; // ✅ now always uses Firestore name
      profileImageUrl = data["profileImageUrl"] ?? "";
    }

    await FirebaseFirestore.instance
        .collection("messages")
        .doc("global_chat")
        .collection("msgs")
        .add({
          "senderId": user?.uid,
          "senderName": senderName,
          "profileImageUrl": profileImageUrl,
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
    final TextEditingController editController = TextEditingController(
      text: oldText,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Message"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: "Update your message"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection("messages")
                      .doc("global_chat")
                      .collection("msgs")
                      .doc(messageId)
                      .update({
                        "text": editController.text.trim(),
                        "edited": true,
                      });
                }
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
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

  // Format timestamp
  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return "";
    DateTime date = ts.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  // Build avatar
  Widget _buildAvatar(String? profileImageUrl, String? senderName) {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(profileImageUrl),
      );
    } else {
      return CircleAvatar(
        radius: 16,
        child: Text(
          (senderName != null && senderName.isNotEmpty)
              ? senderName[0].toUpperCase()
              : "U",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Chat"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Messages Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .doc("global_chat")
                  .collection("msgs")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data["senderId"] == user?.uid;

                    return GestureDetector(
                      onLongPress: isMe
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          title: const Text("Edit"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _editMessage(
                                              docs[index].id,
                                              data["text"],
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          title: const Text("Delete"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _deleteMessage(docs[index].id);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            _buildAvatar(
                              data["profileImageUrl"],
                              data["senderName"],
                            ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue.shade200
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe
                                      ? const Radius.circular(12)
                                      : const Radius.circular(0),
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      data["senderName"] ?? "Unknown",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    data["text"] ?? "",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      data.containsKey("edited") &&
                                              data["edited"] == true
                                          ? "${_formatTimestamp(data["timestamp"])} • Edited"
                                          : _formatTimestamp(data["timestamp"]),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe)
                            _buildAvatar(
                              data["profileImageUrl"],
                              data["senderName"],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Field
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: const Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 0, 170, 255),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
