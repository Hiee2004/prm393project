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
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(_controller.value);
            final pulse = 1 + math.sin(_controller.value * math.pi * 6) * 0.035;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB700),
                    Color(0xFFFFC928),
                    Color(0xFFFFE7A6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  ...List.generate(12, (index) {
                    return _FallingSplashLeaf(
                      progress: (_controller.value + index * 0.09) % 1,
                      index: index,
                    );
                  }),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: pulse,
                              child: const Text(
                                '🍁',
                                style: TextStyle(
                                  fontSize: 116,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'MyTime',
                              style: TextStyle(
                                color: Color(0xFF2A2418),
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Focus - Plan - Achieve',
                              style: TextStyle(
                                color: Color(0xFF5C4614),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 72,
                    right: 72,
                    bottom: 44,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 5,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.32),
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

class _FallingSplashLeaf extends StatelessWidget {
  const _FallingSplashLeaf({required this.progress, required this.index});

  final double progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final left = ((index * 83) % 100) / 100 * size.width;
    final drift = math.sin((progress + index) * math.pi * 2) * 34;
    final opacity = 0.10 + (index % 4) * 0.04;

    return Positioned(
      left: left + drift,
      top: size.height * progress - 80,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: progress * math.pi * 2 + index,
          child: Text(
            '🍁',
            style: TextStyle(
              fontSize: 18 + (index % 5) * 7,
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
        ),
      ),
    );
  }
}
