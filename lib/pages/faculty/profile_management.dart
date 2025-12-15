import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

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

  static const String cloudName = "dhwt8lr4p";
  static const String uploadPreset = "McaVerse";

  // Blood group options
  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown'
  ];

  // Year of study options
  final List<String> studyYears = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    // 🔐 prevents dropdown crash
  String? safeDropdownValue(String value, List<String> items) {
    if (items.contains(value)) return value;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final doc = await _firestore.collection("users").doc(user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        name = data["name"] ?? "";
        email = data["email"] ?? user!.email!;
        phone = data["phone"] ?? "";
        dob = data["dob"] ?? "";
        regNo = data["regNo"] ?? "";
        bloodGroup = bloodGroups.contains(data["bloodGroup"])
          ? data["bloodGroup"]
          : "";
        status = data["status"] ?? "";
         yearOfStudy = studyYears.contains(data["yearOfStudy"])
          ? data["yearOfStudy"]
          : "";
        faculty = data["faculty"] ?? "";
        alumniYears = data["alumniYears"] ?? "";
        profileImageUrl = data["profileImageUrl"] ?? "";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        _profileImageWeb = await picked.readAsBytes();
      } else {
        _profileImage = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dob.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(dob)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C5364),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF203A43),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dob = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<String> _uploadToCloudinary() async {
    if (_profileImage == null && _profileImageWeb == null) {
      return profileImageUrl;
    }

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri);
    request.fields["upload_preset"] = uploadPreset;

    if (kIsWeb && _profileImageWeb != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          _profileImageWeb!,
          filename: "profile.png",
        ),
      );
    } else if (_profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("file", _profileImage!.path),
      );
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["secure_url"];
    } else {
      throw Exception("Cloudinary upload failed");
    }
  }

  Future<void> _saveProfile() async {
    if (user == null || !_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final newImageUrl = await _uploadToCloudinary();

      await _firestore.collection("users").doc(user!.uid).update({
        "name": name,
        "phone": phone,
        "dob": dob,
        "regNo": regNo,
        "bloodGroup": bloodGroup,
        "yearOfStudy": yearOfStudy,
        "faculty": faculty,
        "alumniYears": alumniYears,
        "profileImageUrl": newImageUrl,
        "updatedAt": Timestamp.now(),
      });

      setState(() {
        profileImageUrl = newImageUrl;
        _isEditing = false;
        _profileImage = null;
        _profileImageWeb = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile updated successfully"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: "Enter $label",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              errorStyle: const TextStyle(color: Colors.orangeAccent),
            ),
            onChanged: onChanged,
            validator: (val) {
              if (isRequired && (val == null || val.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
            keyboardType: keyboardType,
            maxLines: maxLines,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : "Not specified",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: value.isNotEmpty ? value : null,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintText: "Select $label",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              dropdownColor: const Color(0xFF203A43),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              style: const TextStyle(color: Colors.white),
              validator: (val) {
                if (isRequired && (val == null || val.isEmpty)) {
                  return 'Please select $label';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4CA1AF),
                      Color(0xFF2C5364),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : _profileImageWeb != null
                          ? Image.memory(_profileImageWeb!, fit: BoxFit.cover)
                          : profileImageUrl.isNotEmpty
                              ? Image.network(profileImageUrl,
                                  fit: BoxFit.cover)
                              : Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2C5364),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 20),
                      color: Colors.white,
                      onPressed: _pickImage,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name.isNotEmpty ? name : "No Name",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: status == "Student"
                  ? Colors.blue.withOpacity(0.2)
                  : status == "Faculty"
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: status == "Student"
                    ? Colors.blue
                    : status == "Faculty"
                        ? Colors.green
                        : Colors.orange,
                width: 1,
              ),
            ),
            child: Text(
              status.isNotEmpty ? status : "Unknown",
              style: TextStyle(
                color: status == "Student"
                    ? Colors.blue.shade300
                    : status == "Faculty"
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return FloatingActionButton.extended(
      onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
      backgroundColor: const Color(0xFF2C5364),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      icon: Icon(_isEditing ? Icons.save : Icons.edit),
      label: Text(_isEditing ? "SAVE CHANGES" : "EDIT PROFILE"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
         automaticallyImplyLeading: false, 
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),

      floatingActionButton: _buildEditButton(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        
                        // Profile Content Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Personal Information",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 16),

                              // Personal Details
                              if (_isEditing) ...[
                                _buildEditableField(
                                  label: "Full Name",
                                  value: name,
                                  onChanged: (v) => name = v,
                                  isRequired: true,
                                ),
                                _buildEditableField(
                                  label: "Registration Number",
                                  value: regNo,
                                  onChanged: (v) => regNo = v,
                                  isRequired: true,
                                ),
                                _buildEditableField(
                                  label: "Phone Number",
                                  value: phone,
                                  onChanged: (v) => phone = v,
                                  keyboardType: TextInputType.phone,
                                ),
                                
                                // Date of Birth with date picker
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Date of Birth",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      InkWell(
                                        onTap: () {
  FocusScope.of(context).unfocus(); // 🔥 FIX
  _pickDate();
},

                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  dob.isNotEmpty ? dob : "Select Date",
                                                  style: TextStyle(
                                                    color: dob.isNotEmpty
                                                        ? Colors.white
                                                        : Colors.white.withOpacity(0.5),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.calendar_today,
                                                color: Colors.white70,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                _buildDropdownField(
                                  label: "Blood Group",
                                  value: bloodGroup,
                                  items: bloodGroups,
                                  onChanged: (v) => bloodGroup = v ?? '',
                                ),
                              ] else ...[
                                _buildReadOnlyField("Full Name", name),
                                _buildReadOnlyField("Registration No.", regNo),
                                _buildReadOnlyField("Phone", phone),
                                _buildReadOnlyField("Date of Birth", dob),
                                _buildReadOnlyField("Blood Group", bloodGroup),
                              ],

                              // Status-specific fields
                              if (status == "Student") ...[
                                const SizedBox(height: 20),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 16),
                                const Text(
                                  "Academic Information",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                if (_isEditing)
                                  _buildDropdownField(
                                    label: "Year of Study",
                                    value: yearOfStudy,
                                    items: studyYears,
                                    onChanged: (v) => yearOfStudy = v ?? '',
                                  )
                                else
                                  _buildReadOnlyField("Year of Study", yearOfStudy),
                              ],

                              if (status == "Faculty" && !_isEditing)
                                _buildReadOnlyField("Faculty", faculty),
                              if (status == "Alumni" && !_isEditing)
                                _buildReadOnlyField("Alumni Years", alumniYears),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}