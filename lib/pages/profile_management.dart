import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _isLoading = false;

  String name = "";
  String email = "";
  String phone = "";
  String dob = "";
  String regNo = "";
  String bloodGroup = "";
  String status = "";
  String yearOfStudy = "";
  String faculty = "";
  String alumniYears = "";
  String profileImageUrl = "";

  File? _profileImage;
  Uint8List? _profileImageWeb;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await _firestore.collection("users").doc(user!.uid).get();

    if (doc.exists) {
      setState(() {
        name = doc["name"] ?? "";
        email = doc["email"] ?? user!.email!;
        phone = doc["phone"] ?? "";
        dob = doc["dob"] ?? "";
        regNo = doc["regNo"] ?? "";
        bloodGroup = doc["bloodGroup"] ?? "";
        status = doc["status"] ?? "";
        yearOfStudy = doc["yearOfStudy"] ?? "";
        faculty = doc["faculty"] ?? "";
        alumniYears = doc["alumniYears"] ?? "";
        profileImageUrl = doc["profileImageUrl"] ?? "";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        _profileImageWeb = await pickedFile.readAsBytes();
      } else {
        _profileImage = File(pickedFile.path);
      }
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    String newImageUrl = profileImageUrl;

    // Upload image if changed
    if (_profileImage != null || _profileImageWeb != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user!.uid}.png');

      try {
        if (kIsWeb && _profileImageWeb != null) {
          await ref.putData(
            _profileImageWeb!,
            SettableMetadata(contentType: 'image/png'),
          );
        } else if (_profileImage != null) {
          await ref.putFile(_profileImage!);
        }
        newImageUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Image upload failed')));
        }
      }
    }

    await _firestore.collection("users").doc(user!.uid).set({
      "name": name,
      "email": email,
      "phone": phone,
      "dob": dob,
      "regNo": regNo,
      "bloodGroup": bloodGroup,
      "status": status,
      "yearOfStudy": yearOfStudy,
      "faculty": faculty,
      "alumniYears": alumniYears,
      "profileImageUrl": newImageUrl,
    }, SetOptions(merge: true));

    setState(() {
      profileImageUrl = newImageUrl;
      _isEditing = false;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  Widget _buildField(
    String label,
    String value, {
    required ValueChanged<String> onChanged,
    bool readOnly = false,
  }) {
    if (_isEditing && !readOnly) {
      return TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      );
    } else {
      return ListTile(
        title: Text(label),
        subtitle: Text(value.isNotEmpty ? value : "-"),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Management"),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (_profileImageWeb != null
                                    ? MemoryImage(_profileImageWeb!)
                                    : (profileImageUrl.isNotEmpty
                                          ? NetworkImage(profileImageUrl)
                                          : null))
                                as ImageProvider<Object>?,
                      child:
                          (_profileImage == null &&
                              _profileImageWeb == null &&
                              profileImageUrl.isEmpty)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildField("Name", name, onChanged: (v) => name = v),
                _buildField(
                  "Email",
                  email,
                  onChanged: (v) => email = v,
                  readOnly: true,
                ),
                _buildField("Phone", phone, onChanged: (v) => phone = v),
                _buildField("Date of Birth", dob, onChanged: (v) => dob = v),
                _buildField("Reg No", regNo, onChanged: (v) => regNo = v),
                _buildField(
                  "Blood Group",
                  bloodGroup,
                  onChanged: (v) => bloodGroup = v,
                ),
                _buildField("Status", status, onChanged: (v) => status = v),
                if (status == "Student")
                  _buildField(
                    "Year of Study",
                    yearOfStudy,
                    onChanged: (v) => yearOfStudy = v,
                  ),
                if (status == "Faculty")
                  _buildField(
                    "Faculty",
                    faculty,
                    onChanged: (v) => faculty = v,
                  ),
                if (status == "Alumni")
                  _buildField(
                    "Alumni Years",
                    alumniYears,
                    onChanged: (v) => alumniYears = v,
                  ),
              ],
            ),
    );
  }
}
