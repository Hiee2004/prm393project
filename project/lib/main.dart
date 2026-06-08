import 'package:flutter/material.dart';
import 'package:project/screens/add_focus_task_screen.dart';
import 'package:project/screens/home_screen.dart';
import 'package:project/screens/login_screen.dart';
import 'package:project/screens/task_detail_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/add_focus_task_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/focus_timer_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/calendar_screen.dart';

void main() {
  runApp(const TimeMateApp());
}

class TimeMateApp extends StatelessWidget {
  const TimeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeMate',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F7FF),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),

        '/tasks': (context) => const TaskListScreen(),
        '/add-task': (context) => const AddFocusTaskScreen(),
        '/task-detail': (context) => const TaskDetailScreen(),
        '/focus': (context) => const FocusTimerScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/calendar': (context) => const CalendarScreen(),
      },
    );
  }
}

class DemoScreen extends StatelessWidget {
  final String title;

  const DemoScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
