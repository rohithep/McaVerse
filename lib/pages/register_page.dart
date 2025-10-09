import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'home_page.dart'; // Adjust path if needed

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _regNoController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _facultyController = TextEditingController();
  final _alumniYearsController = TextEditingController();
  final _phoneController = TextEditingController();

  String _status = 'Student';
  String _yearOfStudy = '1st Year';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _profileImage;
  Uint8List? _profileImageWeb;

  /// Pick image for mobile or web
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

  /// Register user and save data
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String profileImageUrl = '';

      if (_profileImage != null || _profileImageWeb != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${userCred.user!.uid}.png');

        try {
          if (kIsWeb && _profileImageWeb != null) {
            await ref.putData(
              _profileImageWeb!,
              SettableMetadata(contentType: 'image/png'),
            );
          } else if (_profileImage != null) {
            await ref.putFile(_profileImage!);
          }
          profileImageUrl = await ref.getDownloadURL();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image upload failed, continuing without it'),
              ),
            );
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'dob': _dobController.text.trim(),
            'phone': _phoneController.text.trim(),
            'regNo': _regNoController.text.trim(),
            'bloodGroup': _bloodGroupController.text.trim(),
            'status': _status,
            'yearOfStudy': _yearOfStudy,
            'faculty': _facultyController.text.trim(),
            'alumniYears': _alumniYearsController.text.trim(),
            'profileImageUrl': profileImageUrl,
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful!')));

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const beginOffset = Offset(0, 0.3);
            const endOffset = Offset.zero;
            final tweenOffset = Tween(
              begin: beginOffset,
              end: endOffset,
            ).chain(CurveTween(curve: Curves.easeInOut));
            final tweenOpacity = Tween<double>(begin: 0, end: 1);

            return SlideTransition(
              position: animation.drive(tweenOffset),
              child: FadeTransition(
                opacity: animation.drive(tweenOpacity),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    bool obscureText = false,
    VoidCallback? toggleObscure,
    bool isObscure = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      suffixIcon: obscureText
          ? IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: toggleObscure,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Animated Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// Glassmorphic Card
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// Profile Image
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white24,
                          backgroundImage: kIsWeb
                              ? (_profileImageWeb != null
                                    ? MemoryImage(_profileImageWeb!)
                                    : null)
                              : (_profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null),
                          child:
                              (_profileImage == null &&
                                  _profileImageWeb == null)
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.white70,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      /// Name
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration("Full Name"),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v!.isEmpty ? "Enter your name" : null,
                      ),
                      const SizedBox(height: 12),

                      /// Email
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration("Email"),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) =>
                            v!.isEmpty ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 12),

                      /// Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          "Password",
                          obscureText: true,
                          toggleObscure: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          isObscure: _obscurePassword,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      /// Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDecoration(
                          "Confirm Password",
                          obscureText: true,
                          toggleObscure: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          isObscure: _obscureConfirmPassword,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      /// Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration("Phone Number"),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      /// DOB
                      TextFormField(
                        controller: _dobController,
                        decoration: _inputDecoration("Date of Birth"),
                        style: const TextStyle(color: Colors.white),
                        onTap: () async {
                          FocusScope.of(context).requestFocus(FocusNode());
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            _dobController.text =
                                "${picked.day}/${picked.month}/${picked.year}";
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      /// Reg No
                      TextFormField(
                        controller: _regNoController,
                        decoration: _inputDecoration("Registration Number"),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      /// Blood Group
                      DropdownButtonFormField<String>(
                        value: _bloodGroupController.text.isNotEmpty
                            ? _bloodGroupController.text
                            : null,
                        decoration: _inputDecoration("Blood Group"),
                        dropdownColor: Colors.black87,
                        items:
                            ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                .map(
                                  (bg) => DropdownMenuItem(
                                    value: bg,
                                    child: Text(
                                      bg,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() => _bloodGroupController.text = val!);
                        },
                      ),
                      const SizedBox(height: 12),

                      /// Status
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: _inputDecoration("Status"),
                        dropdownColor: Colors.black87,
                        items: ['Student', 'Faculty', 'Alumni']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _status = val!);
                        },
                      ),
                      const SizedBox(height: 12),

                      if (_status == "Student")
                        DropdownButtonFormField<String>(
                          value: _yearOfStudy,
                          decoration: _inputDecoration("Year of Study"),
                          dropdownColor: Colors.black87,
                          items: ["1st Year", "2nd Year"]
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    y,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _yearOfStudy = val!);
                          },
                        ),
                      if (_status == "Faculty")
                        TextFormField(
                          controller: _facultyController,
                          decoration: _inputDecoration("Faculty"),
                          style: const TextStyle(color: Colors.white),
                        ),
                      if (_status == "Alumni")
                        TextFormField(
                          controller: _alumniYearsController,
                          decoration: _inputDecoration("Years of Study"),
                          style: const TextStyle(color: Colors.white),
                        ),

                      const SizedBox(height: 24),

                      /// Register Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blueAccent.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: Colors.blueAccent.withValues(
                              alpha: 0.6,
                            ),

                            elevation: 6,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
