import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/services/focus_notification_service.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/shared/widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FocusNotificationService.instance.initialize();
  runApp(const MyTimeApp());
}

class MyTimeApp extends StatelessWidget {
  const MyTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MyTimeStore.instance,
      builder: (context, child) {
        final themeMode = MyTimeStore.instance.profile.themeMode;

        return MaterialApp(
          title: 'MyTime',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forMode(themeMode),
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          builder: (context, child) {
            return AppBackground(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
