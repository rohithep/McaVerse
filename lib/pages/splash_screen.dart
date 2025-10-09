import 'package:flutter/material.dart';
import 'dart:async';
import 'welcome_page.dart';
import 'package:audioplayers/audioplayers.dart';

class McaVerseSplashScreen extends StatefulWidget {
  @override
  _McaVerseSplashScreenState createState() => _McaVerseSplashScreenState();
}

class _McaVerseSplashScreenState extends State<McaVerseSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _mScaleAnimation;
  late Animation<Offset> _mSlideAnimation;
  late List<Animation<double>> _letterFadeAnimations;
  late Animation<double> _shineAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String appName = "caVerse";

  @override
  void initState() {
    super.initState();
    _playIntroSound();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    );

    _mScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _mSlideAnimation = Tween<Offset>(begin: Offset(0.3, 0), end: Offset(0, 0))
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );

    _letterFadeAnimations = List.generate(appName.length, (index) {
      double start = 0.4 + index * 0.1;
      double end = (start + 0.3).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _shineAnimation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // wait extra 2 seconds after animation
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WelcomePage()),
            );
          }
        });
      }
    });
  }

  Future<void> _playIntroSound() async {
    await _audioPlayer.play(AssetSource('sounds/intro.mp3'));
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget buildLetters(double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(appName.length, (index) {
        return FadeTransition(
          opacity: _letterFadeAnimations[index],
          child: Stack(
            children: [
              Text(
                appName[index],
                style: TextStyle(
                  fontFamily: "BebasNeue",
                  color: Colors.red[800],
                  fontSize: fontSize,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.red.withOpacity(0.6), blurRadius: 15),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _shineAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.9),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: [
                          (_shineAnimation.value - 0.2).clamp(0.0, 1.0),
                          _shineAnimation.value.clamp(0.0, 1.0),
                          (_shineAnimation.value + 0.2).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      appName[index],
                      style: TextStyle(
                        fontFamily: "BebasNeue",
                        fontSize: fontSize,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double mFontSize = screenWidth * 0.25;
    double letterFontSize = screenWidth * 0.18;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FractionalTranslation(
                translation: _mSlideAnimation.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: _mScaleAnimation.value,
                      child: Text(
                        "M",
                        style: TextStyle(
                          fontFamily: "BebasNeue",
                          color: Colors.red[800],
                          fontSize: mFontSize,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 5,
                          shadows: [
                            Shadow(
                              color: Colors.redAccent.withOpacity(0.8),
                              blurRadius: 30,
                            ),
                            Shadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 60,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    buildLetters(letterFontSize),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
