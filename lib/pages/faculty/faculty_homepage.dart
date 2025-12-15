import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../profile_management.dart';
import '../messages_page.dart';
import '../faculty/faculty_dashboard_page.dart';
import 'dart:math';

class FacultyHomepage extends StatefulWidget {
  const FacultyHomepage({super.key});

  @override
  State<FacultyHomepage> createState() => _FacultyDashboardPageState();
}

class _FacultyDashboardPageState extends State<FacultyHomepage>
    with TickerProviderStateMixin {
  int _currentIndex = 2; // Default = Dashboard
  final User? user = FirebaseAuth.instance.currentUser;
  final FlutterTts _tts = FlutterTts();
  bool _welcomed = false;

  late final List<Widget> _pages;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _speakWelcome();

    // Faculty-specific tabs
    _pages = [
      const MessagesPage(),
      const Center(
        child: Text("Faculty Gallery", style: TextStyle(fontSize: 20)),
      ),
      const FacultyDashboardPage(), // can customize dashboard for faculty
      const Center(
        child: Text("Announcements", style: TextStyle(fontSize: 20)),
      ),
      const ProfileManagementPage(),
    ];

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  Future<void> _speakWelcome() async {
    if (_welcomed) return;
    _welcomed = true;

    final name = user?.displayName ?? user?.email?.split('@')[0] ?? "Faculty";

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    await _tts.speak("Welcome $name");
  }

  @override
  void dispose() {
    _tts.stop();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'Faculty';

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Gradient Background
          Container(
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

          // Particle Background
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(_particleController.value),
                child: Container(),
              );
            },
          ),

          // Content with AppBar
          SafeArea(
            child: Column(
              children: [
                // Glass AppBar
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await FirebaseAuth.instance.signOut();
                          navigator.pushReplacementNamed('/login');
                        },
                      ),
                    ],
                  ),
                ),

                // Active Page
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _pages[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Glass BottomNavigationBar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: "Messages",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library),
              label: "Gallery",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: "Announce",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

/// Particle painter for animated background
class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .15);

    for (int i = 0; i < 40; i++) {
      final dx = (size.width * ((i * 73) % 100) / 100) + 20 * sin(progress + i);
      final dy =
          (size.height * ((i * 41) % 100) / 100) + 30 * cos(progress + i * 2);
      canvas.drawCircle(Offset(dx, dy), 2 + (i % 3).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
