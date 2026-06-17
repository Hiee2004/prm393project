import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FocusNotificationService {
  FocusNotificationService._();

  static final FocusNotificationService instance = FocusNotificationService._();

  static const int _notificationId = 1001;
  static const String _channelId = 'focus_timer';
  static const String _channelName = 'Focus Timer';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!_isAndroid) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_focus'),
    );

    await _notifications.initialize(settings: settings);
    _isInitialized = true;
  }

  Future<void> showRunning({
    required String taskTitle,
    required String remainingTime,
  }) async {
    await _show(
      title: 'Focus Time - $remainingTime',
      body: taskTitle,
      ongoing: true,
    );
  }

  Future<void> showPaused({
    required String taskTitle,
    required String remainingTime,
  }) async {
    await _show(
      title: 'Focus Time paused - $remainingTime',
      body: taskTitle,
      ongoing: true,
    );
  }

  Future<void> showCompleted({required String taskTitle}) async {
    await _show(
      title: 'Focus session complete',
      body: taskTitle,
      ongoing: false,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  Future<void> cancel() async {
    if (!_isInitialized) return;
    await _notifications.cancel(id: _notificationId);
  }

  Future<void> _show({
    required String title,
    required String body,
    required bool ongoing,
    Importance importance = Importance.low,
    Priority priority = Priority.low,
  }) async {
    if (!_isInitialized) return;

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Shows the active MyTime focus session.',
        importance: importance,
        priority: priority,
        ongoing: ongoing,
        autoCancel: !ongoing,
        onlyAlertOnce: ongoing,
        showWhen: false,
        category: AndroidNotificationCategory.progress,
      ),
    );

    await _notifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: 'focus_time',
    );
  }
}
