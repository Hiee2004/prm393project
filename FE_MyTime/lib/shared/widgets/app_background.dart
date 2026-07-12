import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:project/core/theme/app_theme.dart';

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
      duration: const Duration(seconds: 18),
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
    final scene = theme.extension<AppSceneTheme>()!;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: scene.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ScenePainter(
                    progress: disableAnimations ? 0 : _controller.value,
                    scene: scene,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -30,
            child: _SoftGlow(size: 220, color: scene.glowPrimary),
          ),
          Positioned(
            left: -80,
            bottom: 120,
            child: _SoftGlow(size: 260, color: scene.glowSecondary),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    scene.overlay,
                    scene.overlay.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = disableAnimations ? 0.0 : _controller.value;
                return Stack(
                  children: switch (scene.effectStyle) {
                    SceneEffectStyle.snow => _buildSnow(scene, progress),
                    SceneEffectStyle.wave => _buildSummer(scene, progress),
                    SceneEffectStyle.lights => _buildChristmas(scene, progress),
                    SceneEffectStyle.petals => _buildLunar(scene, progress),
                  },
                );
              },
            ),
          ),
          RepaintBoundary(child: widget.child),
        ],
      ),
    );
  }

  List<Widget> _buildSnow(AppSceneTheme scene, double progress) {
    return List.generate(10, (index) {
      final t = (progress + index * 0.07) % 1;
      final sway = math.sin((t * math.pi * 2) + index) * 20;
      return Positioned(
        left: 18 + (index * 22) + sway,
        top: -20 + (t * 900),
        child: Opacity(
          opacity: 0.20 + ((index % 4) * 0.08),
          child: Icon(
            index.isEven ? Icons.ac_unit_rounded : Icons.circle,
            size: index.isEven ? 12.0 : 6.0,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  List<Widget> _buildSummer(AppSceneTheme scene, double progress) {
    return [
      Positioned(
        top: 54,
        right: 38,
        child: Transform.scale(
          scale: 0.96 + math.sin(progress * math.pi * 2) * 0.04,
          child: Icon(
            Icons.wb_sunny_rounded,
            size: 74,
            color: Colors.white.withValues(alpha: 0.36),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _WavePainter(
              progress: progress,
              primary: scene.glowPrimary.withValues(alpha: 0.26),
              secondary: scene.glowSecondary.withValues(alpha: 0.24),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildChristmas(AppSceneTheme scene, double progress) {
    return List.generate(10, (index) {
      final t = (progress + index * 0.06) % 1;
      final pulse =
          0.35 + ((math.sin((progress * math.pi * 2) + index) + 1) / 2) * 0.55;
      return Positioned(
        left: 12 + (index * 24),
        top: 60 + (math.sin(t * math.pi * 2) * 18) + ((index % 2) * 22),
        child: Opacity(
          opacity: pulse,
          child: Icon(
            index.isEven ? Icons.circle : Icons.star_rounded,
            size: index.isEven ? 8 : 12,
            color: index % 3 == 0
                ? const Color(0xFFFFF1A8)
                : (index % 3 == 1
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF43F5E)),
          ),
        ),
      );
    });
  }

  List<Widget> _buildLunar(AppSceneTheme scene, double progress) {
    final fireworks = List.generate(3, (index) {
      final local = (progress + index * 0.28) % 1;
      final burst = Curves.easeOut.transform((local * 1.3).clamp(0.0, 1.0));
      return Positioned(
        right: 26 + (index * 80),
        top: 78 + (index * 34),
        child: Opacity(
          opacity: (1 - burst).clamp(0.0, 0.65),
          child: Container(
            width: 22 + (burst * 42),
            height: 22 + (burst * 42),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: index.isEven
                    ? const Color(0xFFFFF1A8)
                    : const Color(0xFFFF7A59),
                width: 1.4,
              ),
            ),
          ),
        ),
      );
    });

    final petals = List.generate(10, (index) {
      final t = (progress + index * 0.08) % 1;
      final sway = math.sin((t * math.pi * 2) + index) * 30;
      return Positioned(
        left: 16 + (index * 24) + sway,
        top: -12 + (t * 860),
        child: Transform.rotate(
          angle: t * math.pi * 2,
          child: Icon(
            index.isEven
                ? Icons.local_florist_rounded
                : Icons.auto_awesome_rounded,
            size: index.isEven ? 16 : 12,
            color: index.isEven
                ? const Color(0xFFFFE28A).withValues(alpha: 0.55)
                : const Color(0xFFFFB38A).withValues(alpha: 0.48),
          ),
        ),
      );
    });

    return [...fireworks, ...petals];
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.progress, required this.scene});

  final double progress;
  final AppSceneTheme scene;

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene.effectStyle) {
      case SceneEffectStyle.snow:
        _paintWinter(canvas, size);
      case SceneEffectStyle.wave:
        _paintSummer(canvas, size);
      case SceneEffectStyle.lights:
        _paintChristmas(canvas, size);
      case SceneEffectStyle.petals:
        _paintLunar(canvas, size);
    }
  }

  void _paintWinter(Canvas canvas, Size size) {
    final hillPaint = Paint()..color = const Color(0x33FFFFFF);
    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.60,
        size.width * 0.40,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.86,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hillPaint);
  }

  void _paintSummer(Canvas canvas, Size size) {
    final beachPaint = Paint()..color = const Color(0x55FFF1C8);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      beachPaint,
    );

    final seaPaint = Paint()..color = const Color(0x3346C7F3);
    final path = Path()..moveTo(0, size.height * 0.74);
    for (double x = 0; x <= size.width + 20; x += 20) {
      final y =
          size.height * 0.74 +
          math.sin((x / size.width * math.pi * 4) + (progress * math.pi * 2)) *
              10;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, seaPaint);
  }

  void _paintChristmas(Canvas canvas, Size size) {
    final treePaint = Paint()..color = const Color(0x6634D399);
    final tree = Path()
      ..moveTo(size.width * 0.10, size.height * 0.80)
      ..lineTo(size.width * 0.22, size.height * 0.42)
      ..lineTo(size.width * 0.34, size.height * 0.80)
      ..close();
    canvas.drawPath(tree, treePaint);

    final tree2 = Path()
      ..moveTo(size.width * 0.74, size.height * 0.82)
      ..lineTo(size.width * 0.85, size.height * 0.48)
      ..lineTo(size.width * 0.96, size.height * 0.82)
      ..close();
    canvas.drawPath(tree2, treePaint..color = const Color(0x554ADE80));
  }

  void _paintLunar(Canvas canvas, Size size) {
    final lanternPaint = Paint()..color = const Color(0x44FFFFFF);
    for (final offset in [
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.24),
    ]) {
      canvas.drawCircle(offset, 18, lanternPaint);
      canvas.drawRect(
        Rect.fromCenter(center: offset.translate(0, 28), width: 2, height: 24),
        lanternPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter other) {
    return other.progress != progress || other.scene != scene;
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas: canvas,
      size: size,
      baseHeight: size.height * 0.82,
      amplitude: 14,
      wavelength: 1.5,
      phase: progress * math.pi * 2,
      color: secondary,
    );
    _drawWave(
      canvas: canvas,
      size: size,
      baseHeight: size.height * 0.86,
      amplitude: 18,
      wavelength: 1.1,
      phase: (progress * math.pi * 2) + 1.8,
      color: primary,
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double baseHeight,
    required double amplitude,
    required double wavelength,
    required double phase,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, baseHeight);

    for (double x = 0; x <= size.width + 10; x += 10) {
      final y =
          baseHeight +
          math.sin((x / size.width * math.pi * 2 * wavelength) + phase) *
              amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter other) {
    return other.progress != progress ||
        other.primary != primary ||
        other.secondary != secondary;
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
