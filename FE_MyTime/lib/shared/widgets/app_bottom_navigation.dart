import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 68,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 14,
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
              color: selected ? primary : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
