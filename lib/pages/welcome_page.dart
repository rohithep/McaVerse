import 'package:flutter/material.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(180, 42),
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.85),

          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
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
          color: Colors.black.withValues(alpha: 0.3),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo / App Name
                Column(
                  children: const [
                    SizedBox(height: 60),
                    Text(
                      "McaVerse",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Welcome to the MCA Association App",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(179, 0, 0, 0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // Main Buttons
                Column(
                  children: [
                    _buildButton('Login', () {
                      Navigator.pushNamed(context, '/login');
                    }),
                    const SizedBox(height: 10),
                    _buildButton('Register', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    }),

                    const SizedBox(height: 10),
                    _buildButton('Login as Guest', () {
                      // You can implement guest login or navigate to home directly
                      Navigator.pushReplacementNamed(context, '/home');
                    }),
                  ],
                ),

                // Footer with About, Contacts, and ©
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFooterLink('About', () {}),
                        const SizedBox(width: 20),
                        _buildFooterLink('Contacts', () {}),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "© Rohith EP",
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
