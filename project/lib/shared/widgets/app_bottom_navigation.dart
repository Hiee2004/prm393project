import 'package:flutter/material.dart';
import 'package:project/core/constants/app_colors.dart';
import 'package:project/core/routes/app_routes.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.tasks,
    AppRoutes.focus,
    AppRoutes.statistics,
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceSoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index != selectedIndex) {
          Navigator.pushReplacementNamed(context, _routes[index]);
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.checklist_outlined),
          label: 'Tasks',
        ),
        NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Focus'),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Statistics',
        ),
      ],
    );
  }
}
