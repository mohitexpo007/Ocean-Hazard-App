import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    // Play sound + start fade
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _player.play(AssetSource('sounds/emergency_ping.mp3'));
        _fadeController.forward();
      }
    });

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (_, __) => Opacity(
          opacity: _fadeAnimation.value,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🌅 Ocean background
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/ocean_splash.png"), // ✅ add in assets
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 🌊 Centered Logo + Text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/ocean_logo.png", // ✅ your wave logo asset
                      height: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "समुद्र रक्षक",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Ocean Guardian",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
