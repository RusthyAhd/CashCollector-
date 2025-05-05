// Add this dependency in pubspec.yaml if not already added:
// dependencies:
//   google_fonts: ^6.1.0

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'home_screen.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> with TickerProviderStateMixin {
  late final AnimationController _pulse, _fadeSlide, _dots, _stars;
  late final Animation<double> _scale, _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _fadeSlide =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward();
    _dots =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
    _stars =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    _scale = Tween(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeSlide, curve: Curves.easeIn));
    _slide = Tween(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeSlide, curve: Curves.easeOut));

    Timer(const Duration(seconds: 5), () {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const RoutePage()));
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _fadeSlide.dispose();
    _dots.dispose();
    _stars.dispose();
    super.dispose();
  }

  Widget _dot(int i) => AnimatedBuilder(
        animation: _dots,
        builder: (_, __) {
          final p = (_dots.value * 3 - i).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1 + (1 - p) * 0.4,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: CircleAvatar(radius: 3, backgroundColor: Colors.white70),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _stars,
        builder: (_, __) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D3B2E), Color(0xFF114D36)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: _StarPainter(_stars.value),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: Colors.white24, width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.25),
                                  blurRadius: 30),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/cash.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Shimmer.fromColors(
                        baseColor: Colors.tealAccent.shade100,
                        highlightColor: Colors.white,
                        child: Text(
                          'Pegas Flex',
                          style: GoogleFonts.orbitron(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, _dot)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double progress;
  final Random _rnd = Random();
  _StarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.2);
    for (int i = 0; i < 60; i++) {
      final dx = _rnd.nextDouble() * size.width;
      final dy =
          (_rnd.nextDouble() * size.height + progress * 50) % size.height;
      canvas.drawCircle(Offset(dx, dy), _rnd.nextDouble() * 1.2 + 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
