import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// --- CLOUDINARY CONFIGURATION (REPLACE WITH YOUR ACTUAL DETAILS) ---
const String _CLOUDINARY_CLOUD_NAME = 'dhwt8lr4p'; // e.g., 'dhwt8lr4p'
const String _CLOUDINARY_UPLOAD_PRESET = 'McaVerse'; // e.g., 'McaVerse'
const String _CLOUDINARY_UPLOAD_URL =
    'https://api.cloudinary.com/v1_1/$_CLOUDINARY_CLOUD_NAME/auto/upload';
// -------------------------------------------------------------------

// Assuming you have a way to securely delete from Cloudinary (e.g., a Cloud Function endpoint)
// We will use a placeholder for the delete API call in this client-side code, 
// but remember, secure deletion requires a backend function!
const String _CLOUDINARY_DELETE_ENDPOINT = 'YOUR_SECURE_CLOUD_FUNCTION_ENDPOINT'; 


class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final user = FirebaseAuth.instance.currentUser!;
  String _userStatus = 'Student'; // Default, will be fetched in initState

  @override
  void initState() {
    super.initState();
    _fetchUserStatus();
  }

  // --- 1. Role Fetching ---
  Future<void> _fetchUserStatus() async {
    if (user.uid.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userStatus = userDoc.get('status') ?? 'Student';
        });
      }
    } catch (e) {
      print("Error fetching user status: $e");
    }
  }

  // --- 2. Upload Logic ---
  Future<String?> _uploadFileToCloudinary(PlatformFile file, String publicId) async {
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File data is missing.')));
      }
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_CLOUDINARY_UPLOAD_URL),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      request.fields['upload_preset'] = _CLOUDINARY_UPLOAD_PRESET;
      request.fields['public_id'] = publicId; // Set the ID for deletion control
      request.fields['folder'] = 'gallery/student_media';
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Return the secure URL
        return data['secure_url'] as String?;
      } else {
        print("Cloudinary Upload Error Status: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload Failed (Status: ${response.statusCode})')),
          );
        }
        return null;
      }
    } catch (e) {
      print("Cloudinary Upload Exception: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      return null;
    }
  }

  // --- 3. Core Action Logic ---

  Future<void> _deletePost(String postId, String publicId) async {
    if (!mounted) return;
    
    // IMPORTANT: In a real app, this should be a call to a Firebase Cloud Function
    // that safely handles the Cloudinary API key for deletion.
    // The client should only delete the Firestore document if the Cloudinary delete succeeds.
    // For this demonstration, we simulate success:

    try {
      // 1. Simulate Cloudinary deletion (REPLACE WITH SECURE CLOUD FUNCTION CALL)
      await Future.delayed(const Duration(milliseconds: 500)); 
      print("Simulating deletion of Cloudinary ID: $publicId");
      
      // 2. Delete Firestore Document
      await FirebaseFirestore.instance.collection('student_posts').doc(postId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully.')),
        );
      }
    } catch (e) {
      print("Deletion error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post.')),
        );
      }
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    final uid = user.uid;
    bool isLiking = !currentLikes.contains(uid);

    await FirebaseFirestore.instance.collection('student_posts').doc(postId).update({
      'likes': isLiking
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> _toggleFeature(String postId, bool isCurrentlyFeatured) async {
    if (_userStatus != 'Faculty' && _userStatus != 'Admin') return;
    
    await FirebaseFirestore.instance.collection('student_posts').doc(postId).update({
      'isFeatured': !isCurrentlyFeatured,
    });
  }

  // --- UI Components ---

  // Shows the modal for the user to select file and enter a title.
  void _showUploadModal() {
    final titleController = TextEditingController();
    FilePickerResult? selectedFile;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Color(0xFF203a43), // Dark themed modal background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "New Gallery Post",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Divider(color: Colors.white54),
                    const SizedBox(height: 16),

                    // Title Input
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Post Title (Required)',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white38),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7CB342))),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // File Selection Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
                        );
                        setModalState(() {
                          selectedFile = result;
                        });
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        selectedFile == null 
                            ? "Select Picture or Video" 
                            : selectedFile!.files.first.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: const Color(0xFF2c5364),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Upload Button
                    ElevatedButton(
                      onPressed: selectedFile != null && titleController.text.isNotEmpty
                          ? () async {
                              Navigator.pop(context); // Close modal first
                              await _handleMediaUpload(titleController.text, selectedFile!.files.first);
                            }
                          : null,
                      child: const Text("Upload Post"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: const Color(0xFF7CB342),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Final upload and metadata commit
  Future<void> _handleMediaUpload(String title, PlatformFile file) async {
    // Show a loading indicator in the main screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading "${file.name}"...')),
    );
    
    // Generate unique Public ID
    final publicId = 'gallery/${user.uid}/${DateTime.now().millisecondsSinceEpoch}';

    final downloadUrl = await _uploadFileToCloudinary(file, publicId);

    if (downloadUrl != null) {
      String mediaType = ['mp4', 'mov'].contains(file.extension?.toLowerCase()) ? 'video' : 'image';

      await FirebaseFirestore.instance.collection('student_posts').add({
        'title': title,
        'uploaderUid': user.uid,
        'uploaderName': user.displayName ?? 'Student User', 
        'mediaUrl': downloadUrl,
        'publicId': publicId,
        'mediaType': mediaType,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'isFeatured': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post uploaded successfully!')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Determine if the current user has administrative rights
    final isFacultyOrAdmin = _userStatus == 'Faculty' || _userStatus == 'Admin';

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0f2027), Color(0xFF203a43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          isFacultyOrAdmin ? "Faculty Gallery Control" : "Student Gallery",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadModal,
        label: const Text("Upload"),
        icon: const Icon(Icons.upload),
        backgroundColor: const Color(0xFF7CB342),
        foregroundColor: Colors.white,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("student_posts")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No posts in the gallery yet!", style: TextStyle(color: Colors.white70)),
              );
            }

            final posts = snapshot.data!.docs;
            
            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Larger tiles
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.85, // More space for title/likes
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index].data() as Map<String, dynamic>;
                return _buildGalleryTile(context, posts[index].id, postData);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGalleryTile(
      BuildContext context, String postId, Map<String, dynamic> data) {
    final bool isImage = data['mediaType'] == 'image';
    final bool isOwner = data['uploaderUid'] == user.uid;
    final bool isFacultyOrAdmin = _userStatus == 'Faculty' || _userStatus == 'Admin';
    final List<dynamic> likes = data['likes'] ?? [];
    final bool isLiked = likes.contains(user.uid);
    final bool isFeatured = data['isFeatured'] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: isFeatured ? Border.all(color: const Color(0xFF7CB342), width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Display Area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    data['mediaUrl'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Colors.white70));
                    },
                    errorBuilder: (context, error, stackTrace) => 
                        const Center(child: Icon(Icons.error, color: Colors.red)),
                  ),
                  
                  // Media Type Icon
                  Positioned(
                    top: 8, right: 8,
                    child: Icon(
                      isImage ? Icons.photo_camera : Icons.videocam,
                      color: Colors.white.withOpacity(0.9),
                      size: 30,
                    ),
                  ),

                  // Featured Badge
                  if (isFeatured)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7CB342),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("FEATURED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Details Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "By: ${data['uploaderName']}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                
                // Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like Button
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white70,
                          ),
                          onPressed: () => _toggleLike(postId, likes),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          '${likes.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    
                    // Options Button (Edit/Delete)
                    if (isOwner || isFacultyOrAdmin)
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white70),
                        onPressed: () => _showPostOptions(context, postId, data, isOwner, isFacultyOrAdmin),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostOptions(
      BuildContext context, String postId, Map<String, dynamic> data, bool isOwner, bool isFacultyOrAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF203a43),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit Title (Owner Only)
              if (isOwner)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text('Edit Title', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement title edit modal
                  },
                ),
              
              // Faculty Feature Toggle (Faculty/Admin Only)
              if (isFacultyOrAdmin)
                ListTile(
                  leading: Icon(
                    data['isFeatured'] ? Icons.star : Icons.star_border,
                    color: data['isFeatured'] ? Colors.amber : Colors.white,
                  ),
                  title: Text(
                    data['isFeatured'] ? 'Un-Feature Post' : 'Feature Post',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFeature(postId, data['isFeatured'] ?? false);
                  },
                ),

              // Delete Post (Owner or Faculty/Admin)
              if (isOwner || isFacultyOrAdmin)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: Text(
                    isFacultyOrAdmin && !isOwner
                        ? 'Delete (Faculty Override)'
                        : 'Delete Post',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost(postId, data['publicId']);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}