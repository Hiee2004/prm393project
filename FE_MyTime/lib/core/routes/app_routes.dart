import 'package:flutter/material.dart';
import 'package:project/screens/add_focus_task_screen.dart';
import 'package:project/screens/ai_dashboard_screen.dart';
import 'package:project/screens/calendar_screen.dart';
import 'package:project/screens/focus_timer_screen.dart';
import 'package:project/screens/focus_audio_settings_screen.dart';
import 'package:project/screens/home_screen.dart';
import 'package:project/screens/login_screen.dart';
import 'package:project/screens/notifications_screen.dart';
import 'package:project/screens/onboarding_screen.dart';
import 'package:project/screens/profile_screen.dart';
import 'package:project/screens/productivity_streak_screen.dart';
import 'package:project/screens/register_screen.dart';
import 'package:project/screens/settings_screen.dart';
import 'package:project/screens/splash_screen.dart';
import 'package:project/screens/statistics_screen.dart';
import 'package:project/screens/task_detail_screen.dart';
import 'package:project/screens/task_list_screen.dart';
import 'package:project/screens/edit_profile_screen.dart';
import 'package:project/screens/smart_task_plan_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String tasks = '/tasks';
  static const String addTask = '/add-task';
  static const String taskDetail = '/task-detail';
  static const String focus = '/focus';
  static const String statistics = '/statistics';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String focusAudioSettings = '/focus-audio-settings';
  static const String calendar = '/calendar';
  static const String editProfile = '/edit-profile';
  static const String aiDashboard = '/ai-dashboard';
  static const String productivityStreak = '/productivity-streak';
  static const String smartTaskPlan = '/smart-task-plan';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),
    tasks: (_) => const TaskListScreen(),
    addTask: (_) => const AddFocusTaskScreen(),
    taskDetail: (_) => const TaskDetailScreen(),
    focus: (_) => const FocusTimerScreen(),
    statistics: (_) => const StatisticsScreen(),
    profile: (_) => const ProfileScreen(),
    notifications: (_) => const NotificationsScreen(),
    settings: (_) => const SettingsScreen(),
    focusAudioSettings: (_) => const FocusAudioSettingsScreen(),
    calendar: (_) => const CalendarScreen(),
    editProfile: (_) => const EditProfileScreen(),
    aiDashboard: (_) => const AiDashboardScreen(),
    productivityStreak: (_) => const ProductivityStreakScreen(),
    smartTaskPlan: (_) => const SmartTaskPlanScreen(),
  };
}
