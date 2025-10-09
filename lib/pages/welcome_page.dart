import 'package:flutter/material.dart';
import 'dart:math';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _buttonController;
  late AnimationController _particleController;

  late Animation<double> _fadeTitle;
  late Animation<Offset> _slideTitle;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeTitle = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    );

    _slideTitle = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 800), () {
      _buttonController.forward();
    });

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Widget _glassButton(String text, VoidCallback onPressed) {
    return FadeTransition(
      opacity: _buttonController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
            ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),

            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),

                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(220, 52),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: onPressed,
            child: Text(text),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // Floating Animated Particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Center section (title + tagline + buttons)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title + Tagline
                        FadeTransition(
                          opacity: _fadeTitle,
                          child: SlideTransition(
                            position: _slideTitle,
                            child: Column(
                              children: const [
                                Text(
                                  "McaVerse",
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Your Gateway to MCA Association",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Buttons
                        _glassButton("Login", () {
                          Navigator.pushNamed(context, '/login');
                        }),
                        _glassButton("Register", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        }),
                        _glassButton("Login as Guest", () {
                          Navigator.pushReplacementNamed(context, '/home');
                        }),
                      ],
                    ),
                  ),
                ),

                // Footer at bottom
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "© Rohith EP",
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Particle Painter for floating circles with animation
class ParticlePainter extends CustomPainter {
  final double progress;

  final int particleCount = 80;

  ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);

    for (int i = 0; i < particleCount; i++) {
      final dx = (i * 73 % size.width) + 50 * sin(progress * 2 * pi + i);
      final dy =
          (i * 101 % size.height) + 40 * cos(progress * 2 * pi + i * 1.3);

      final radius = (i % 3 + 1).toDouble();
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
