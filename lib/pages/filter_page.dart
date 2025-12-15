import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _faculty;

  // Available options
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

  final List<String> studyYears = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year'
  ];

  final List<String> statusList = [
    'Student',
    'Alumni',
    'Faculty'
  ];

  final List<String> faculties = [
    'Computer Science',
    'Engineering',
    'Business',
    'Medicine',
    'Arts',
    'Science',
    'Law'
  ];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
      _faculty = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Filters reset'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  bool get _hasFilters {
    return _nameController.text.isNotEmpty ||
        _bloodGroupController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _regNoController.text.isNotEmpty ||
        _yearOfStudy != null ||
        _status != null ||
        _faculty != null;
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection("users");

    if (_nameController.text.isNotEmpty) {
      final name = _nameController.text.trim().toLowerCase();
      query = query.where("nameSearch",
          isGreaterThanOrEqualTo: name, isLessThan: name + 'z');
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
    if (_faculty != null) {
      query = query.where("faculty", isEqualTo: _faculty);
    }

    return query.limit(100).snapshots();
  }

  Widget _buildFilterField({
    required String label,
    required IconData icon,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child!,
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data) {
    final status = data['status'] ?? '';
    final statusColor = status == 'Student'
        ? Colors.blue
        : status == 'Faculty'
            ? Colors.green
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Optional: Navigate to user profile
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: data['profileImageUrl'] != null &&
                            data['profileImageUrl'].toString().isNotEmpty
                        ? Image.network(
                            data['profileImageUrl'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['regNo'] ?? 'No Reg No',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (data['yearOfStudy'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.blue, width: 0.5),
                              ),
                              child: Text(
                                data['yearOfStudy'].toString(),
                                style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (data['bloodGroup'] != null &&
                              data['bloodGroup'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.red, width: 0.5),
                              ),
                              child: Text(
                                data['bloodGroup'].toString(),
                                style: TextStyle(
                                  color: Colors.red.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor, width: 0.5),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // More Info Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Filter Users",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _hasFilters ? Colors.white : Colors.white54,
            ),
            tooltip: "Reset Filters",
            onPressed: _hasFilters ? _resetFilters : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
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
        child: SafeArea(
          child: Column(
            children: [
              // Filter Cards
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Filters Indicator
                      if (_hasFilters)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt, size: 18, color: Colors.blue.shade300),
                              const SizedBox(width: 8),
                              Text(
                                'Filters Active',
                                style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Filter Fields
                      _buildFilterField(
                        label: 'Name',
                        icon: Icons.person,
                        child: TextField(
                          controller: _nameController,
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
                              vertical: 12,
                            ),
                            hintText: 'Search by name...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterField(
                              label: 'Registration No',
                              icon: Icons.badge,
                              child: TextField(
                                controller: _regNoController,
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
                                    vertical: 12,
                                  ),
                                  hintText: 'Reg number...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilterField(
                              label: 'Phone',
                              icon: Icons.phone,
                              child: TextField(
                                controller: _phoneController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText: 'Phone number...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ),
                        ],
                      ),

                      _buildFilterField(
                        label: 'Blood Group',
                        icon: Icons.bloodtype,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _bloodGroupController.text.isNotEmpty
                                ? _bloodGroupController.text
                                : null,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'Select blood group',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              ...bloodGroups.map((group) {
                                return DropdownMenuItem<String>(
                                  value: group,
                                  child: Text(
                                    group,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _bloodGroupController.text = value ?? '';
                              });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            dropdownColor: const Color(0xFF203A43),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white70),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterField(
                              label: 'Status',
                              icon: Icons.verified_user,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _status,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'All status',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                    ...statusList.map((status) {
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _status = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16),
                                  ),
                                  dropdownColor: const Color(0xFF203A43),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.white70),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilterField(
                              label: 'Year of Study',
                              icon: Icons.school,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _yearOfStudy,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'All years',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                    ...studyYears.map((year) {
                                      return DropdownMenuItem<String>(
                                        value: year,
                                        child: Text(
                                          year,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _yearOfStudy = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16),
                                  ),
                                  dropdownColor: const Color(0xFF203A43),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.white70),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      _buildFilterField(
                        label: 'Faculty',
                        icon: Icons.business,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _faculty,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All faculties',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                              ...faculties.map((faculty) {
                                return DropdownMenuItem<String>(
                                  value: faculty,
                                  child: Text(
                                    faculty,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _faculty = value;
                              });
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            dropdownColor: const Color(0xFF203A43),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white70),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Results Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Search Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _buildQuery(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Text(
                          '$count found',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Results List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: _hasFilters
                      ? StreamBuilder<QuerySnapshot>(
                          stream: _buildQuery(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 50,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading data',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No users found',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your filters',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                return _buildUserCard(data);
                              },
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_outlined,
                                size: 80,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Apply filters to search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use the form above to find users',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
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
    final paint = Paint()..color = Colors.white.withOpacity(0.05);

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