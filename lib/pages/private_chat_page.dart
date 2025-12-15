import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // REMOVED: No longer needed
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; // USED for Cloudinary Upload

// --- CLOUDINARY CONFIGURATION ---
const String _CLOUDINARY_CLOUD_NAME = 'dhwt8lr4p';
const String _CLOUDINARY_UPLOAD_PRESET = 'McaVerse';
const String _CLOUDINARY_UPLOAD_URL =
    'https://api.cloudinary.com/v1_1/$_CLOUDINARY_CLOUD_NAME/auto/upload';
// ---------------------------------

class PrivateChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? otherUserName;

  const PrivateChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.otherUserName,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool showEmoji = false;

  // Particle system for background effect
  List<Particle> particles = [];
  AnimationController? _animationController;

  // Typing status logic
  bool _isTyping = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });

    _animationController!.repeat();

    _initParticles();
    _markMessagesAsRead();

    controller.addListener(_updateTypingStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- Read Receipts Logic ---
  Future<void> _markMessagesAsRead() async {
    final chatRef = FirebaseFirestore.instance
        .collection("private_chats")
        .doc(widget.chatId)
        .collection("messages");

    final unreadMessages = await chatRef
        .where('senderId', isEqualTo: widget.otherUserId)
        .where('status', isNotEqualTo: 'read')
        .get();

    for (var doc in unreadMessages.docs) {
      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(doc.reference, {'status': 'read'});
      });
    }
  }

  // --- Typing Status Logic ---
  void _updateTypingStatus() {
    if (controller.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      // TODO: Update Firestore status for 'isTyping' = true
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (_isTyping) {
        _isTyping = false;
        // TODO: Update Firestore status for 'isTyping' = false
      }
    });
  }

  // -----------------------------------------------
  // --- CLOUDINARY FILE UPLOAD IMPLEMENTATION ---
  // -----------------------------------------------

  Future<String?> _uploadFileToCloudinary(PlatformFile file) async {
    if (file.bytes == null) {
      print("File bytes are null. Cannot upload.");
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_CLOUDINARY_UPLOAD_URL),
      );

      // Add the file part
      request.files.add(http.MultipartFile.fromBytes(
        'file', // Key expected by Cloudinary
        file.bytes!,
        filename: file.name,
      ));

      // Add the required upload preset
      request.fields['upload_preset'] = _CLOUDINARY_UPLOAD_PRESET;
      
      // Optional: Add a folder name if desired
      request.fields['folder'] = 'McaVerse/private_chats/${widget.chatId}';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?; // Return the secure URL
      } else {
        print("Cloudinary Upload Error Status: ${response.statusCode}");
        print("Response Body: ${response.body}");
        // Show user friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload file to Cloudinary.')),
        );
        return null;
      }
    } catch (e) {
      print("Cloudinary Upload Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      return null;
    }
  }

  // Updated _uploadFile method
  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;

      // Call the Cloudinary upload utility
      final downloadUrl = await _uploadFileToCloudinary(file);

      if (downloadUrl != null) {
        // Determine file type
        String fileType = 'file';
        if (['jpg', 'jpeg', 'png', 'gif'].contains(file.extension?.toLowerCase())) {
          fileType = 'image';
        }

        // Send message with Cloudinary URL
        await _sendMediaMessage(
          downloadUrl,
          fileType,
          file.name,
        );
      } else {
        // Error handling already in _uploadFileToCloudinary
      }
    }
  }
  
  // -----------------------------------------------
  
  Future<void> _sendMediaMessage(
    String url,
    String fileType,
    String fileName,
  ) async {
    final chatRef = FirebaseFirestore.instance.collection("private_chats").doc(widget.chatId);

    await chatRef.set({
      "members": [user.uid, widget.otherUserId],
      "lastMessage": fileType == 'image' ? 'Image' : 'File: $fileName',
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection("messages").add({
      "senderId": user.uid,
      "text": fileName, // Use filename as text content
      "url": url,
      "fileType": fileType,
      "type": fileType,
      "timestamp": FieldValue.serverTimestamp(),
      "status": "sent",
    });

    _scrollToBottom();
  }

  void _initParticles() {
    particles = List.generate(20, (index) => Particle());
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final chatRef = FirebaseFirestore.instance
        .collection("private_chats")
        .doc(widget.chatId);

    String messageText = controller.text.trim();

    await chatRef.set({
      "members": [user.uid, widget.otherUserId],
      "lastMessage": messageText,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection("messages").add({
      "senderId": user.uid,
      "text": messageText,
      "type": "text",
      "timestamp": FieldValue.serverTimestamp(),
      "status": "sent",
    });

    controller.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.removeListener(_updateTypingStatus);
    controller.dispose();
    _animationController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildAnimatedBackground(),

          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("private_chats")
                      .doc(widget.chatId)
                      .collection("messages")
                      .orderBy("timestamp")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final msgs = snapshot.data!.docs;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final data =
                            msgs[index].data() as Map<String, dynamic>;
                        final isMe = data["senderId"] == user.uid;
                        final timestamp = data["timestamp"] as Timestamp?;
                        final status = data["status"] as String? ?? 'sent';

                        return _buildMessageBubble(
                          data,
                          isMe,
                          timestamp,
                          status,
                          showTime: index == msgs.length - 1 ||
                              (index < msgs.length - 1 &&
                                _isDifferentSender(msgs, index)),
                        );
                      },
                    );
                  },
                ),
              ),

              if (showEmoji)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      controller.text += emoji.emoji;
                    },
                    config: const Config(
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28,
                      ),
                    ),
                  ),
                ),

              _buildInputArea(),

            ],
          ),
        ],
      ),
    );
  }

  bool _isDifferentSender(List<QueryDocumentSnapshot> msgs, int index) {
    if (index + 1 >= msgs.length) return true;

    final currentData = msgs[index].data() as Map<String, dynamic>;
    final nextData = msgs[index + 1].data() as Map<String, dynamic>;

    return currentData["senderId"] != nextData["senderId"];
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> data,
    bool isMe,
    Timestamp? timestamp,
    String status,
    {bool showTime = true}
  ) {
    final text = data["text"] as String? ?? '';
    final type = data["type"] as String? ?? 'text';
    final url = data["url"] as String?;

    Widget content;

    if (type == 'image' && url != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150,
              width: 150,
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Text('Error loading image', style: TextStyle(color: Colors.white)),
        ),
      );
    } else if (type == 'file' && url != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
            ),
          ),
        ],
      );
      // TODO: Add onTap to launch file URL
    }
    else {
      content = Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      );
    }


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMe
                    ? [
                        const Color(0xFF2c5364),
                        const Color(0xFF203a43),
                      ]
                    : [
                        Colors.grey.shade800.withOpacity(0.8),
                        Colors.grey.shade900.withOpacity(0.8),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (showTime && timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(timestamp.toDate()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatusIcon(status),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(String status) {
    IconData icon;
    Color color = Colors.white.withOpacity(0.7);

    switch (status) {
      case 'read':
        icon = Icons.done_all;
        color = const Color(0xFF7CB342);
        break;
      case 'delivered':
        icon = Icons.done_all;
        break;
      case 'sent':
      default:
        icon = Icons.done;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f2027),
              Color(0xFF203a43),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2c5364),
                  Color(0xFF203a43),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName ?? "Chat",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user_statuses')
                    .doc(widget.otherUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  // TODO: Implement logic to read 'isTyping' or 'lastSeen' from snapshot
                  String statusText = "Online";

                  return Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      leading: IconButton(
        icon: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
          onPressed: () {
            setState(() {
                showEmoji = !showEmoji;
            });
          },

        ),
      ],
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0f2027).withOpacity(0.95),
            const Color(0xFF203a43).withOpacity(0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2c5364),
                  Color(0xFF203a43),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: _uploadFile,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),

              child: TextField(
                controller: controller,
                maxLines: null,
                onSubmitted: (_) => sendMessage(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                        showEmoji = !showEmoji;
                        });
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2c5364),
                  Color(0xFF203a43),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2c5364).withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final controller = _animationController;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0f2027),
                Color(0xFF203a43),
                Color(0xFF2c5364),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        if (controller != null)
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(particles, controller.value),
                child: Container(),
              );
            },
          ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

// Particle system classes
class Particle {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double speed = 0.5 + Random().nextDouble() * 0.5;
  double size = 2 + Random().nextDouble() * 3;
  Color color = const Color(0xFF2c5364).withOpacity(0.3 + Random().nextDouble() * 0.2);
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      paint.color = particle.color;
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );

      particle.y += (particle.speed / 1000) * (animationValue * 10);
      if (particle.y > 1) {
        particle.y = 0;
        particle.x = Random().nextDouble();
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}