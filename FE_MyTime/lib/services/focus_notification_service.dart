import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum FocusNotificationAction { pause, resume }

class FocusNotificationService {
  FocusNotificationService._();

  static final FocusNotificationService instance = FocusNotificationService._();

  static const String pauseActionId = 'pause_focus';
  static const String resumeActionId = 'resume_focus';
  static const int _notificationId = 1001;
  static const String _channelId = 'focus_timer';
  static const String _channelName = 'Focus Timer';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<FocusNotificationAction> _actionController =
      StreamController<FocusNotificationAction>.broadcast();

  bool _isInitialized = false;

  Stream<FocusNotificationAction> get actions => _actionController.stream;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!_isAndroid) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_focus'),
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        switch (response.actionId) {
          case pauseActionId:
            _actionController.add(FocusNotificationAction.pause);
            break;
          case resumeActionId:
            _actionController.add(FocusNotificationAction.resume);
            break;
        }
      },
    );
    _isInitialized = true;
  }

  Future<void> showRunning({
    required String taskTitle,
    required String remainingTime,
  }) async {
    await _show(
      title: 'Focus Time - $remainingTime',
      body: '$taskTitle - Tap Pause to stop the sand.',
      ongoing: true,
      actions: const [
        AndroidNotificationAction(
          pauseActionId,
          'Pause',
          showsUserInterface: true,
        ),
      ],
    );
  }

  Future<void> showPaused({
    required String taskTitle,
    required String remainingTime,
  }) async {
    await _show(
      title: 'Focus Time paused - $remainingTime',
      body: '$taskTitle - Tap Continue when ready.',
      ongoing: true,
      actions: const [
        AndroidNotificationAction(
          resumeActionId,
          'Continue',
          showsUserInterface: true,
        ),
      ],
    );
  }

  Future<void> showCompleted({required String taskTitle}) async {
    await _show(
      title: 'Focus session complete',
      body: taskTitle,
      ongoing: false,
      importance: Importance.high,
      priority: Priority.high,
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
    List<AndroidNotificationAction>? actions,
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
        playSound: !ongoing,
        showWhen: false,
        category: AndroidNotificationCategory.progress,
        actions: actions,
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
