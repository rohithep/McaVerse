import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'profile_management.dart'; // Import your ProfileManagementPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Default tab = Homepage
  final User? user = FirebaseAuth.instance.currentUser;
  final FlutterTts _tts = FlutterTts();
  bool _welcomed = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _speakWelcome();

    // Tabs for bottom navigation
    _pages = [
      const Center(child: Text("Messages", style: TextStyle(fontSize: 20))),
      const Center(child: Text("Gallery", style: TextStyle(fontSize: 20))),
      const Center(child: Text("Homepage", style: TextStyle(fontSize: 20))),
      const Center(
        child: Text("Announcements", style: TextStyle(fontSize: 20)),
      ),
      const ProfileManagementPage(), // ✅ Profile tab
    ];
  }

  Future<void> _speakWelcome() async {
    if (_welcomed) return;
    _welcomed = true;

    final name = user?.displayName ?? user?.email?.split('@')[0] ?? "User";

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    await _tts.speak("Welcome $name");
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade50,
        elevation: 1,
        title: Text(
          user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue.shade900),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // show current tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue.shade50,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
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
    );
  }
}
