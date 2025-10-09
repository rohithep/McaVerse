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
      final data = doc.data() ?? {};
      setState(() {
        name = data["name"] ?? "";
        email = data["email"] ?? user!.email!;
        phone = data["phone"] ?? "";
        dob = data["dob"] ?? "";
        regNo = data["regNo"] ?? "";
        bloodGroup = data["bloodGroup"] ?? "";
        status = data["status"] ?? "";
        yearOfStudy = data["yearOfStudy"] ?? "";
        faculty = data["faculty"] ?? "";
        alumniYears = data["alumniYears"] ?? "";
        profileImageUrl = data["profileImageUrl"] ?? "";
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

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: dob.isNotEmpty
          ? DateTime.tryParse(dob) ?? DateTime(2000)
          : DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => dob = pickedDate.toIso8601String().split('T').first);
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
    bool isDate = false,
  }) {
    if (_isEditing && !readOnly) {
      if (isDate) {
        return TextFormField(
          readOnly: true,
          onTap: _selectDate,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(text: dob),
        );
      }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile Management",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
              ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
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
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blueAccent,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Card(
                    color: Colors.white.withOpacity(0.1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(_isEditing),
                          children: [
                            _buildField(
                              "Name",
                              name,
                              onChanged: (v) => name = v,
                            ),
                            _buildField(
                              "email",
                              email,
                              onChanged: (v) => email = v,
                              readOnly: true,
                            ),
                            _buildField(
                              "Phone",
                              phone,
                              onChanged: (v) => phone = v,
                            ),
                            _buildField(
                              "Date of Birth",
                              dob,
                              onChanged: (v) => dob = v,
                              isDate: true,
                            ),
                            _buildField(
                              "Reg No",
                              regNo,
                              onChanged: (v) => regNo = v,
                            ),
                            _buildField(
                              "Blood Group",
                              bloodGroup,
                              onChanged: (v) => bloodGroup = v,
                            ),

                            // Dropdown for Status
                            _isEditing
                                ? DropdownButtonFormField<String>(
                                    value: status.isEmpty ? null : status,
                                    decoration: const InputDecoration(
                                      labelText: "Status",
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: "Student",
                                        child: Text("Student"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Faculty",
                                        child: Text("Faculty"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Alumni",
                                        child: Text("Alumni"),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => status = v ?? ""),
                                  )
                                : ListTile(
                                    title: const Text("Status"),
                                    subtitle: Text(
                                      status.isNotEmpty ? status : "-",
                                    ),
                                  ),

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
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
