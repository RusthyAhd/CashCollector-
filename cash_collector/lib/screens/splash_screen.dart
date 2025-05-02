import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textPulseController;
  late AnimationController _dotsController;

  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textPulseAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _textPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _textPulseAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(_textPulseController);

    _logoController.forward();

    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AreaPage()),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textPulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        double progress = _dotsController.value * 3;
        double opacity = (progress - index).clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - opacity,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.5),
            child: CircleAvatar(radius: 4, backgroundColor: Colors.green),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: FadeTransition(
          opacity: _logoFadeAnimation,
          child: SlideTransition(
            position: _logoSlideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Image.asset(
                    'assets/images/cash.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: _textPulseAnimation,
                  child: const Text(
                    'Pegas Flex',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      shadows: [
                        Shadow(
                          blurRadius: 12.0,
                          color: Colors.greenAccent,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, _buildDot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
