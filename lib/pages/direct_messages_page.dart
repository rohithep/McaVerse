import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'private_chat_page.dart';

class DirectMessagesPage extends StatelessWidget {
  DirectMessagesPage({super.key});

  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("private_chats")
            .where("members", arrayContains: myUid)
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text("No messages yet"),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data =
                  chats[index].data() as Map<String, dynamic>;

              final members = List<String>.from(data["members"]);
              final otherUserId =
                  members.firstWhere((id) => id != myUid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();

                  final user =
                      userSnap.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user["profileImageUrl"].isNotEmpty
                              ? NetworkImage(
                                  user["profileImageUrl"])
                              : null,
                      child: user["profileImageUrl"].isEmpty
                          ? Text(user["name"][0])
                          : null,
                    ),
                    title: Text(user["name"]),
                    subtitle: Text(data["lastMessage"] ?? ""),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PrivateChatPage(
                            chatId: chats[index].id,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
