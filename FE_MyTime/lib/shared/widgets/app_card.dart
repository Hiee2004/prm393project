import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;
    final cardColor = color ?? theme.colorScheme.surface;
    final baseAlpha = theme.brightness == Brightness.dark ? 0.62 : 0.68;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withValues(alpha: baseAlpha + 0.12),
                cardColor.withValues(alpha: baseAlpha),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scene.cardBorder),
            boxShadow: [
              BoxShadow(
                color: scene.cardGlow,
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -8,
                right: -6,
                child: Icon(
                  scene.floatingIcon,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.18 : 0.42,
                  ),
                ),
              ),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
