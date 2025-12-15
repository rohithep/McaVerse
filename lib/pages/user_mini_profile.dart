import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'private_chat_page.dart';

class UserMiniProfile extends StatelessWidget {
  final String userId;

  const UserMiniProfile({
    super.key,
    required this.userId,
  });

  // 🔥 Start or open private chat (FIXED TYPES)
  Future<void> _startChat(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    String? chatId;

    // 1️⃣ Check if chat already exists
    final query = await FirebaseFirestore.instance
        .collection("private_chats")
        .where("members", arrayContains: myUid)
        .get();

    for (var doc in query.docs) {
      final members = List<String>.from(doc["members"]);
      if (members.contains(userId)) {
        chatId = doc.id;
        break;
      }
    }

    // 2️⃣ Create new chat if not found
    if (chatId == null) {
      final docRef = await FirebaseFirestore.instance
          .collection("private_chats")
          .add({
        "members": [myUid, userId],
        "lastMessage": "",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      chatId = docRef.id;
    }

    // 3️⃣ Close mini profile
    Navigator.pop(context);

    // 4️⃣ Open private chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatPage(
          chatId: chatId!,
          otherUserId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final name = data["name"] ?? "Unknown";
        final image = data["profileImageUrl"] ?? "";
        final status = data["status"] ?? "";
        final year = data["yearOfStudy"] ?? "";

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage:
                    image.toString().isNotEmpty ? NetworkImage(image) : null,
                child: image.toString().isEmpty
                    ? Text(
                        name.toString().isNotEmpty
                            ? name[0].toUpperCase()
                            : "U",
                        style: const TextStyle(fontSize: 26),
                      )
                    : null,
              ),

              const SizedBox(height: 12),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (status.toString().isNotEmpty ||
                  year.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "$status • $year",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),

              const SizedBox(height: 12),

              _infoRow("Reg No", data["regNo"]),
              _infoRow("Phone", data["phone"]),
              _infoRow("Email", data["email"]),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Message"),
                  onPressed: () => _startChat(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
