import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scene = theme.extension<AppSceneTheme>()!;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 68,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.90 : 0.94,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scene.cardBorder),
        boxShadow: [
          BoxShadow(
            color: scene.navGlow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Item(
            icon: Icons.home_outlined,
            label: "Home",
            selected: selectedIndex == 0,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),

          _Item(
            icon: Icons.checklist_outlined,
            label: "Tasks",
            selected: selectedIndex == 1,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.tasks),
          ),

          _Item(
            icon: Icons.timer_outlined,
            label: "Focus",
            selected: selectedIndex == 2,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.focus),
          ),

          _Item(
            icon: Icons.bar_chart_outlined,
            label: "Stats",
            selected: selectedIndex == 3,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.statistics),
          ),

          _Item(
            icon: Icons.person_outline_rounded,
            label: "Profile",
            selected: selectedIndex == 4,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondaryText = theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              icon,
              color: selected ? primary : secondaryText,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? primary : secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
