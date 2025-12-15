// file: faculty_academics_page.dart
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

/// Full Faculty Academics page with Cloudinary uploads (images + PDFs/raw).
/// Configure cloudName & uploadPreset below.
class FacultyAcademicsPage extends StatelessWidget {
  const FacultyAcademicsPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {
      'title': 'Question Papers',
      'color': Colors.blue,
      'icon': Icons.description,
      'id': 'question_papers',
    },
    {
      'title': 'Notes',
      'color': Colors.green,
      'icon': Icons.menu_book_rounded,
      'id': 'notes',
    },
    {
      'title': 'Syllabus',
      'color': Colors.orange,
      'icon': Icons.list_alt_rounded,
      'id': 'syllabus',
    },
    {
      'title': 'Recorded Lectures',
      'color': Colors.purple,
      'icon': Icons.play_circle_fill_rounded,
      'id': 'recorded_lectures',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Academics"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: categories
              .map(
                (cat) => _FolderCard(
                  title: cat['title'],
                  icon: cat['icon'],
                  color: cat['color'],
                  onTap: () {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please login first")),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FolderListPage(
                          categoryId: cat['id'],
                          categoryTitle: cat['title'],
                          currentUser: user,
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FolderCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderListPage extends StatelessWidget {
  final String categoryId;
  final String categoryTitle;
  final User currentUser;

  const FolderListPage({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final folderCollection = FirebaseFirestore.instance
        .collection('academics')
        .doc(categoryId)
        .collection('folders');

    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.create_new_folder),
        onPressed: () async {
          String folderName = '';
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Create Folder"),
              content: TextField(
                onChanged: (val) => folderName = val,
                decoration: const InputDecoration(hintText: "Folder Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (folderName.isNotEmpty) {
                      try {
                        await folderCollection.add({
                          'folderName': folderName,
                          'createdBy': currentUser.uid,
                          'createdAt': Timestamp.now(),
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Folder created!")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: folderCollection.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final folders = snapshot.data!.docs;

          if (folders.isEmpty) {
            return const Center(child: Text("No folders created yet."));
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final folderName = (folder.data() as Map<String, dynamic>?)?['folderName'] ?? 'Unnamed';
              return ListTile(
                title: Text(folderName),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FileUploadPage(
                        categoryId: categoryId,
                        folderId: folder.id,
                        folderName: folderName,
                        currentUser: currentUser,
                      ),
                    ),
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

// ===================== Stateful FileUploadPage (Option C - Hybrid UI) =====================
class FileUploadPage extends StatefulWidget {
  final String categoryId;
  final String folderId;
  final String folderName;
  final User currentUser;

  const FileUploadPage({
    super.key,
    required this.categoryId,
    required this.folderId,
    required this.folderName,
    required this.currentUser,
  });

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  // ====== Configure these ======
  static const String cloudName = 'dhwt8lr4p'; // <-- set your cloud name
  static const String uploadPreset = 'McaVerse'; // <-- set your unsigned preset
  static const String cloudinaryDeleteEndpoint = ''; // backend endpoint to delete from Cloudinary (optional)
  // =============================

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'pdf', 'image', 'video', 'other'
  Key _streamKey = UniqueKey();

  CollectionReference<Map<String, dynamic>> get fileCollection => FirebaseFirestore
      .instance
      .collection('academics')
      .doc(widget.categoryId)
      .collection('folders')
      .doc(widget.folderId)
      .collection('files');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadWithMetadata() async {
    final user = widget.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    String title = '';
    String description = '';

    // Ask for title & description first
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Upload file - details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title (required)'),
              onChanged: (v) => title = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Short description (optional)'),
              onChanged: (v) => description = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continue')),
        ],
      ),
    );

    if (ok != true) return;
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      final fileName = picked.name;
      final fileExt = picked.extension ?? '';

      final mimeType = lookupMimeType(fileName, headerBytes: picked.bytes) ?? '';
      final isPdf = mimeType.toLowerCase().contains('pdf') || fileExt.toLowerCase() == 'pdf';

      final uploadEndpoint = isPdf ? 'raw/upload' : 'auto/upload';
      final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$uploadEndpoint');

      final request = http.MultipartRequest('POST', uploadUrl);
      request.fields['upload_preset'] = uploadPreset;
      if (isPdf) request.fields['resource_type'] = 'raw';

      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null) throw Exception('No bytes available from file');
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      } else {
        final path = picked.path;
        if (path == null) throw Exception('No file path available');
        final file = File(path);
        final length = await file.length();
        final stream = http.ByteStream(file.openRead());
        request.files.add(http.MultipartFile('file', stream, length, filename: p.basename(path)));
      }

      // show progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      Navigator.of(context).pop();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Upload failed (${response.statusCode}): ${response.body}');
      }

      final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
      // ignore: avoid_print
      print('Cloudinary response: $json');

      final secureUrl = json['secure_url'] as String?;
      final publicId = json['public_id'] as String?;
      final returnedFormat = (json['format'] as String?) ?? fileExt;
      final returnedBytes = (json['bytes'] as int?) ?? 0;

      String effectiveUrl = '';
      if (secureUrl != null && secureUrl.isNotEmpty) effectiveUrl = secureUrl;
      if (effectiveUrl.isEmpty && publicId != null) {
        final safePublic = publicId.toLowerCase().endsWith('.pdf') ? publicId : '$publicId.pdf';
        effectiveUrl = 'https://res.cloudinary.com/$cloudName/raw/upload/fl_attachment/$safePublic';
      }
      if (effectiveUrl.isEmpty) throw Exception('Could not build a valid Cloudinary URL for this file.');

      await fileCollection.add({
        'title': title.trim(),
        'description': description.trim(),
        'fileName': fileName,
        'fileUrl': effectiveUrl,
        'publicId': publicId ?? '',
        'uploadedBy': user.uid,
        'uploadedAt': Timestamp.now(),
        'fileType': returnedFormat,
        'size': returnedBytes,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded successfully')));
      setState(() => _streamKey = UniqueKey());
    } catch (e, st) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      // ignore: avoid_print
      print('Upload error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _deleteFile(DocumentSnapshot doc) async {
    final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
    final title = (data['title'] ?? data['fileName'] ?? 'file').toString();
    final docId = doc.id;
    final publicId = (data['publicId'] ?? '').toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "$title"?'),
        content: const Text('This will remove the file record. You can also delete the file from Cloudinary if your backend supports it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete Firestore doc
      await fileCollection.doc(docId).delete();

      // Optionally call backend to delete file from Cloudinary (requires a backend)
      if (cloudinaryDeleteEndpoint.isNotEmpty && publicId.isNotEmpty) {
        try {
          final resp = await http.post(Uri.parse(cloudinaryDeleteEndpoint),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'public_id': publicId}));
          if (resp.statusCode < 200 || resp.statusCode >= 300) {
            // warn but continue
            // ignore: avoid_print
            print('Cloudinary delete failed: ${resp.statusCode} ${resp.body}');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted; cloud deletion failed')));
            return;
          }
        } catch (e) {
          // ignore: avoid_print
          print('Cloudinary delete call failed: $e');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted; cloud deletion error')));
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted')));
      setState(() => _streamKey = UniqueKey());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // ------------------ new helpers for in-app viewing & downloading ------------------

  Future<void> _openInAppViewer(String url, String fileType, {String? title}) async {
    final t = fileType.toLowerCase();
    try {
      if (t.contains('pdf')) {
        // Download bytes then create a PdfControllerPinch with the Future<PdfDocument>
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode != 200) throw Exception('Could not download PDF for viewing (status ${resp.statusCode})');
        final bytes = resp.bodyBytes;
        if (bytes.isEmpty) throw Exception('Downloaded PDF empty');

        // IMPORTANT: pass Future<PdfDocument> into the controller (do NOT await)
        final futureDoc = PdfDocument.openData(bytes);
        final controller = PdfControllerPinch(document: futureDoc);

        // Push viewer screen that will dispose controller
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PdfViewerScreen(controller: controller, title: title ?? 'PDF'),
        ));
        return;
      }

      if (t.startsWith('image') || t.contains('jpg') || t.contains('png') || t.contains('jpeg') || t.contains('gif')) {
        await showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Container(
                color: Colors.black,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Center(child: Text('Load failed'))),
                ),
              ),
            ),
          ),
        );
        return;
      }

      if (t.startsWith('video') || t.contains('mp4') || t.contains('mov') || t.contains('mkv')) {
        final tmp = await _downloadToTemporary(url);
        if (tmp == null) throw Exception('Could not download video for viewing');
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(file: tmp)));
        return;
      }

      // fallback: open external
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot open file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open failed: $e')));
    }
  }

  Future<File?> _downloadToTemporary(String url) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final filename = Uri.parse(url).pathSegments.isNotEmpty ? Uri.parse(url).pathSegments.last : 'file';
      final savePath = '${tempDir.path}/$filename';
      final resp = await dio.download(url, savePath, options: Options(responseType: ResponseType.bytes));
      if (resp.statusCode == 200 || resp.statusCode == 201) return File(savePath);
    } catch (e) {
      // ignore
      // ignore: avoid_print
      print('tmp download failed: $e');
    }
    return null;
  }

  Future<void> _downloadFile(String url, String filename) async {
    try {
      if (kIsWeb) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opened in browser to download')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open download link')));
        }
        return;
      }

      final dio = Dio();
      String? savePath;

      if (Platform.isAndroid) {
        // Request permission (best-effort)
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // fallback to app dir
          final dir = await getExternalStorageDirectory();
          savePath = '${dir?.path ?? (await getApplicationDocumentsDirectory()).path}/$filename';
        } else {
          // try Downloads folder
          try {
            savePath = '/storage/emulated/0/Download/$filename';
          } catch (_) {
            final dir = await getExternalStorageDirectory();
            savePath = '${dir?.path ?? (await getApplicationDocumentsDirectory()).path}/$filename';
          }
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$filename';
      } else {
        // desktop
        try {
          final downloads = await getDownloadsDirectory();
          savePath = downloads != null ? '${downloads.path}/$filename' : '${(await getTemporaryDirectory()).path}/$filename';
        } catch (_) {
          savePath = '${(await getTemporaryDirectory()).path}/$filename';
        }
      }

      if (savePath == null) throw Exception('Could not determine save path');

      // show simple progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
      );

      final resp = await dio.download(url, savePath, onReceiveProgress: (rec, total) {
        // optional: you can update UI with setState if you want progress
      });

      Navigator.of(context).pop();

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $savePath')));
      } else {
        throw Exception('Download failed: ${resp.statusCode}');
      }
    } catch (e) {
      try {
        Navigator.of(context).pop();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Widget _leadingIcon(String fileType) {
    final t = fileType.toLowerCase();
    if (t.contains('pdf')) return const Icon(Icons.picture_as_pdf, size: 36);
    if (t.contains('mp4') || t.contains('mov') || t.contains('mkv') || t.startsWith('video')) return const Icon(Icons.video_library, size: 36);
    if (t.contains('jpg') || t.contains('png') || t.contains('jpeg') || t.contains('gif') || t.startsWith('image')) return const Icon(Icons.image, size: 36);
    return const Icon(Icons.insert_drive_file, size: 36);
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 ? 2 : 0)} ${suffixes[i]}';
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: Text(widget.folderName)),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.upload_file),
        onPressed: _uploadWithMetadata,
      ),
      body: Column(
        children: [
          // Search & filter row
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by title, filename or description...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Filter files',
                  icon: const Icon(Icons.filter_list),
                  onSelected: (v) => setState(() => _filter = v),
                  itemBuilder: (c) => [
                    const PopupMenuItem(value: 'all', child: Text('All')),
                    const PopupMenuItem(value: 'pdf', child: Text('PDF')),
                    const PopupMenuItem(value: 'image', child: Text('Images')),
                    const PopupMenuItem(value: 'video', child: Text('Videos')),
                    const PopupMenuItem(value: 'other', child: Text('Other')),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => _streamKey = UniqueKey()),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: _streamKey,
              stream: fileCollection.orderBy('uploadedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.where((d) {
                  final Map<String, dynamic> data = (d.data() as Map<String, dynamic>?) ?? {};
                  final title = (data['title'] ?? data['fileName'] ?? '').toString().toLowerCase();
                  final fileName = (data['fileName'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  final fileType = (data['fileType'] ?? '').toString().toLowerCase();

                  if (_filter == 'pdf' && !fileType.contains('pdf')) return false;
                  if (_filter == 'image' && !(fileType.startsWith('image') || fileType.contains('jpg') || fileType.contains('png') || fileType.contains('jpeg') || fileType.contains('gif'))) return false;
                  if (_filter == 'video' && !(fileType.startsWith('video') || fileType.contains('mp4') || fileType.contains('mov') || fileType.contains('mkv'))) return false;
                  if (_filter == 'other' && (fileType.contains('pdf') || fileType.startsWith('image') || fileType.startsWith('video'))) return false;

                  if (query.isEmpty) return true;
                  return title.contains(query) || fileName.contains(query) || desc.contains(query);
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No files match your search'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final Map<String, dynamic> data = (doc.data() as Map<String, dynamic>?) ?? {};
                    final title = (data['title'] ?? data['fileName'] ?? 'Unknown').toString();
                    final desc = (data['description'] ?? '').toString();
                    final fileType = (data['fileType'] ?? '').toString().toLowerCase();
                    final fileUrl = data['fileUrl'] as String?;
                    final size = (data['size'] ?? 0) as int;
                    final ts = data['uploadedAt'] as Timestamp?;

                    // guessed filename for saving
                    final guessedName = (data['fileName'] ?? (fileUrl != null ? Uri.parse(fileUrl).pathSegments.last : 'file')).toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ExpansionTile(
                        leading: _leadingIcon(fileType),
                        title: Text(title),
                        subtitle: Text('${_formatTimestamp(ts)} • ${_formatBytes(size)}'),
                        children: [
                          if (desc.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Align(alignment: Alignment.centerLeft, child: Text(desc)),
                            ),
                          ButtonBar(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('View'),
                                onPressed: fileUrl == null ? null : () => _openInAppViewer(fileUrl, fileType, title: title),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.file_download),
                                label: const Text('Download'),
                                onPressed: fileUrl == null ? null : () => _downloadFile(fileUrl, guessedName),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.open_in_new_outlined),
                                label: const Text('Open external'),
                                onPressed: fileUrl == null
                                    ? null
                                    : () async {
                                        final uri = Uri.parse(fileUrl);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file')));
                                        }
                                      },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () => _deleteFile(doc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------- Pdf viewer screen -----------------------
class PdfViewerScreen extends StatefulWidget {
  final PdfControllerPinch controller;
  final String title;

  const PdfViewerScreen({super.key, required this.controller, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  @override
  void dispose() {
    // PdfControllerPinch.dispose() closes the document as well.
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // optional: page info or search icon later
        ],
      ),
      body: PdfViewPinch(
        controller: widget.controller,
      ),
    );
  }
}

// ---------------------- small video player screen -----------------------
class VideoPlayerScreen extends StatefulWidget {
  final File file;
  const VideoPlayerScreen({super.key, required this.file});

  @override 
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() => _init = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: Center(
        child: _init
            ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
        onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
      ),
    );
  }
}
