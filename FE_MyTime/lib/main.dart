import 'package:flutter/material.dart';
import 'package:project/core/routes/app_routes.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/services/focus_notification_service.dart';
import 'package:project/services/my_time_store.dart';
import 'package:project/services/session_store.dart';
import 'package:project/shared/widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FocusNotificationService.instance.initialize();
  await SessionStore.instance.hydrateFromLocal();
  await MyTimeStore.instance.hydrateThemeFromLocal();
  if (SessionStore.instance.token?.isNotEmpty ?? false) {
    await MyTimeStore.instance.hydrateSettingsFromBackend();
  } else {
    await FocusNotificationService.instance.configureTimeZone('Asia/Ho_Chi_Minh');
  }
  runApp(const MyTimeApp());
}

class MyTimeApp extends StatelessWidget {
  const MyTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: MyTimeStore.instance.themeModeListenable,
      builder: (context, themeMode, child) {
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

//flutter run -d chrome --web-port=58053
//flutter run -d emulator-5554
