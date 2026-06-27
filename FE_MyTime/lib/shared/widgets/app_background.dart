import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF020617), Color(0xFF111827), Color(0xFF0F172A)]
              : [
                  Color.lerp(Colors.white, primary, 0.08)!,
                  Color.lerp(Colors.white, primary, 0.16)!,
                  Color.lerp(Colors.white, secondary, 0.06)!,
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _SoftGlow(
              size: 230,
              color: primary.withValues(alpha: isDark ? 0.18 : 0.13),
            ),
          ),
          Positioned(
            left: -100,
            bottom: 110,
            child: _SoftGlow(
              size: 270,
              color: secondary.withValues(alpha: isDark ? 0.14 : 0.09),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              return Stack(
                children: [
                  _FloatingLeaf(
                    progress: value,
                    color: primary,
                    leftFactor: 0.10,
                    size: 28,
                    delay: 0.00,
                    opacity: 0.12,
                  ),
                  _FloatingLeaf(
                    progress: value,
                    color: primary,
                    leftFactor: 0.74,
                    size: 22,
                    delay: 0.22,
                    opacity: 0.10,
                  ),
                  _FloatingLeaf(
                    progress: value,
                    color: secondary,
                    leftFactor: 0.42,
                    size: 18,
                    delay: 0.46,
                    opacity: 0.08,
                  ),
                  _FloatingLeaf(
                    progress: value,
                    color: primary,
                    leftFactor: 0.88,
                    size: 32,
                    delay: 0.68,
                    opacity: 0.09,
                  ),
                ],
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _FloatingLeaf extends StatelessWidget {
  const _FloatingLeaf({
    required this.progress,
    required this.color,
    required this.leftFactor,
    required this.size,
    required this.delay,
    required this.opacity,
  });

  final double progress;
  final Color color;
  final double leftFactor;
  final double size;
  final double delay;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final t = (progress + delay) % 1;
    final drift = math.sin(t * math.pi * 2) * 24;

    return Positioned(
      left: screen.width * leftFactor + drift,
      top: screen.height * t - 60,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: t * math.pi * 2,
          child: Icon(
            Icons.eco_rounded,
            size: size,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
