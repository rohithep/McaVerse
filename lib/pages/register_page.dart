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

class _RegisterPageState extends State<RegisterPage> {
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
      // 1. Create Firebase Auth user
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String profileImageUrl = '';

      // 2. Upload profile image if selected
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
          // Continue registration even if image upload fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image upload failed, continuing without it'),
              ),
            );
          }
        }
      }

      // 3. Save user data to Firestore
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

      // Navigate to Home with animation
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const beginOffset = Offset(0, 0.3); // Slide from bottom
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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email already registered';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Input decoration helper
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
      fillColor: const Color.fromRGBO(0, 0, 0, 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/ChatGPT Image Aug 13, 2025, 04_51_55 PM.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: const Color.fromRGBO(0, 0, 0, 0.2),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            (_profileImage == null && _profileImageWeb == null)
                            ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name'),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email'),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter email';
                        }
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration(
                        'Password',
                        obscureText: true,
                        toggleObscure: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        isObscure: _obscurePassword,
                      ),
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: _inputDecoration(
                        'Confirm Password',
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
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirm your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration('Phone Number'),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 12),
                    // Date of Birth
                    TextFormField(
                      controller: _dobController,
                      decoration: _inputDecoration('Date of Birth'),
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
                              '${picked.day}/${picked.month}/${picked.year}';
                        }
                      },
                      validator: (value) =>
                          value!.isEmpty ? 'Enter date of birth' : null,
                    ),
                    const SizedBox(height: 12),
                    // Registration Number
                    TextFormField(
                      controller: _regNoController,
                      decoration: _inputDecoration('Registration Number'),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter registration number' : null,
                    ),
                    const SizedBox(height: 12),
                    // Blood Group Dropdown
                    DropdownButtonFormField<String>(
                      value: _bloodGroupController.text.isNotEmpty
                          ? _bloodGroupController.text
                          : null,
                      decoration: _inputDecoration('Blood Group'),
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map(
                            (bg) =>
                                DropdownMenuItem(value: bg, child: Text(bg)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _bloodGroupController.text = val!);
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select blood group'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _inputDecoration('Status'),
                      items: ['Student', 'Faculty', 'Alumni']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _status = val!);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Conditional Fields
                    if (_status == 'Student')
                      DropdownButtonFormField<String>(
                        value: _yearOfStudy,
                        decoration: _inputDecoration('Year of Study'),
                        items: ['1st Year', '2nd Year']
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _yearOfStudy = val!);
                        },
                      ),
                    if (_status == 'Faculty')
                      TextFormField(
                        controller: _facultyController,
                        decoration: _inputDecoration('Faculty'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (_status == 'Alumni')
                      TextFormField(
                        controller: _alumniYearsController,
                        decoration: _inputDecoration(
                          'Years of Study (e.g., 2023-2025)',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blueAccent.withAlpha(230),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
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
      ),
    );
  }
}
