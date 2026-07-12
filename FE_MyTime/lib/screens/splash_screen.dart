import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 1800);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _splashDuration)
      ..forward();

    Future.delayed(_splashDuration, () {
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
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(_controller.value);
            final pulse = 1 + math.sin(_controller.value * math.pi * 6) * 0.035;

            return Container(
              width: double.infinity,
              height: double.infinity,
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
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            scene.overlay,
                            scene.overlay.withValues(alpha: 0.32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(8, (index) {
                    return _FloatingSplashAccent(
                      progress: (_controller.value + index * 0.08) % 1,
                      index: index,
                      icon: scene.floatingIcon,
                      color: theme.colorScheme.onSurface,
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
                              child: Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.surface.withValues(
                                    alpha: isDark ? 0.36 : 0.54,
                                  ),
                                  border: Border.all(color: scene.cardBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scene.navGlow,
                                      blurRadius: 26,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  scene.accentIcon,
                                  size: 64,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'MyTime',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${scene.label} focus world',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.82,
                                ),
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
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surface.withValues(
                          alpha: isDark ? 0.34 : 0.42,
                        ),
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

class _FloatingSplashAccent extends StatelessWidget {
  const _FloatingSplashAccent({
    required this.progress,
    required this.index,
    required this.icon,
    required this.color,
  });

  final double progress;
  final int index;
  final IconData icon;
  final Color color;

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
          child: Icon(
            icon,
            size: 18 + (index % 5) * 7,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
