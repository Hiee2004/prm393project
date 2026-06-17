import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _colorController;

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  Color _animatedColor(List<Color> colors, double value) {
    final total = colors.length;
    final scaled = value * total;
    final index = scaled.floor() % total;
    final nextIndex = (index + 1) % total;
    final t = scaled - scaled.floor();

    return Color.lerp(colors[index], colors[nextIndex], t) ?? colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF43E97B),
      const Color(0xFF38F9D7),
      const Color(0xFF22D3EE),
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _colorController,
          builder: (context, child) {
            final value = _colorController.value;
            final wave = math.sin(value * math.pi * 2);
            final pulse = 1 + wave * 0.04;

            final color1 = _animatedColor(colors, value);
            final color2 = _animatedColor(colors, (value + 0.25) % 1);
            final color3 = _animatedColor(colors, (value + 0.50) % 1);

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + wave * 0.4, -1),
                  end: Alignment(1, 1 + math.cos(value * math.pi * 2) * 0.4),
                  colors: [color1, color2, color3],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -70 + wave * 20,
                    left: -50,
                    child: _GlowCircle(
                      size: 220,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  Positioned(
                    right: -70 + wave * 25,
                    bottom: -90,
                    child: _GlowCircle(
                      size: 280,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    top: 170,
                    right: 45 + wave * 15,
                    child: _GlowCircle(
                      size: 95,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'MyTime',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your smart schedule companion',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 52),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SplashDot(isActive: true),
                            _SplashDot(isActive: false),
                            _SplashDot(isActive: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 42,
                    child: Text(
                      'Focus - Plan - Grow',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SplashDot extends StatelessWidget {
  const _SplashDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.38),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
