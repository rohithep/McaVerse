import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage>
    with SingleTickerProviderStateMixin {
  // Animation Controller for particles
  late AnimationController _particleController;

  // Filters
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();
  String? _yearOfStudy;
  String? _status;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _nameController.dispose();
    _bloodGroupController.dispose();
    _phoneController.dispose();
    _regNoController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _nameController.clear();
      _bloodGroupController.clear();
      _phoneController.clear();
      _regNoController.clear();
      _yearOfStudy = null;
      _status = null;
    });
  }

  bool get _hasFilters {
    return _nameController.text.isNotEmpty ||
        _bloodGroupController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _regNoController.text.isNotEmpty ||
        _yearOfStudy != null ||
        _status != null;
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection("users");

    if (_nameController.text.isNotEmpty) {
      query = query.where("name", isEqualTo: _nameController.text.trim());
    }
    if (_bloodGroupController.text.isNotEmpty) {
      query = query.where(
        "bloodGroup",
        isEqualTo: _bloodGroupController.text.trim(),
      );
    }
    if (_phoneController.text.isNotEmpty) {
      query = query.where("phone", isEqualTo: _phoneController.text.trim());
    }
    if (_regNoController.text.isNotEmpty) {
      query = query.where("regNo", isEqualTo: _regNoController.text.trim());
    }
    if (_yearOfStudy != null) {
      query = query.where("yearOfStudy", isEqualTo: _yearOfStudy);
    }
    if (_status != null) {
      query = query.where("status", isEqualTo: _status);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filter Users"),
        backgroundColor: Colors.indigo,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Reset Filters",
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient Background
          Container(
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

          // Animated Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),

          // Filter Form + Results
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Filters Section
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Name
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "Name",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // Blood Group
                            TextField(
                              controller: _bloodGroupController,
                              decoration: const InputDecoration(
                                labelText: "Blood Group",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.bloodtype),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // Phone
                            TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: "Phone",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // Reg No
                            TextField(
                              controller: _regNoController,
                              decoration: const InputDecoration(
                                labelText: "Registration No",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),

                            // Year of Study
                            DropdownButtonFormField<String>(
                              value: _yearOfStudy,
                              decoration: const InputDecoration(
                                labelText: "Year of Study",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.school),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "1st Year",
                                  child: Text("1st Year"),
                                ),
                                DropdownMenuItem(
                                  value: "2nd Year",
                                  child: Text("2nd Year"),
                                ),
                                DropdownMenuItem(
                                  value: "3rd Year",
                                  child: Text("3rd Year"),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _yearOfStudy = val),
                            ),
                            const SizedBox(height: 10),

                            // Status
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: "Status",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "Student",
                                  child: Text("Student"),
                                ),
                                DropdownMenuItem(
                                  value: "Alumni",
                                  child: Text("Alumni"),
                                ),
                                DropdownMenuItem(
                                  value: "Faculty",
                                  child: Text("Faculty"),
                                ),
                              ],
                              onChanged: (val) => setState(() => _status = val),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Results
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _hasFilters
                          ? StreamBuilder<QuerySnapshot>(
                              stream: _buildQuery(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Center(
                                    child: Text("No students found"),
                                  );
                                }
                                return ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final d =
                                        docs[i].data() as Map<String, dynamic>;
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            d["profileImageUrl"] ??
                                                "https://ui-avatars.com/api/?name=${Uri.encodeComponent((d['name'] ?? 'U').toString())}",
                                          ),
                                        ),
                                        title: Text(d["name"] ?? "Unknown"),
                                        subtitle: Text(
                                          "${d["yearOfStudy"] ?? ""} | ${d["department"] ?? ""} | ${d["status"] ?? ""}",
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : const Center(child: Text("No filters applied")),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle Painter for Animated Background
class ParticlePainter extends CustomPainter {
  final double progress;
  final int particleCount;

  ParticlePainter(this.progress, {this.particleCount = 100});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.08);

    for (int i = 0; i < particleCount; i++) {
      final dx = (i * 67 % size.width) + 50 * sin(progress * 2 * pi + i);
      final dy = (i * 89 % size.height) + 40 * cos(progress * 2 * pi + i * 1.2);

      final radius = (i % 3 + 1).toDouble();
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
