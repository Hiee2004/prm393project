import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:project/models/focus_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum FocusNotificationAction { pause, resume }

class FocusNotificationService {
  FocusNotificationService._();

  static final FocusNotificationService instance = FocusNotificationService._();

  static const String pauseActionId = 'pause_focus';
  static const String resumeActionId = 'resume_focus';
  static const int _notificationId = 1001;
  static const String _channelId = 'focus_timer';
  static const String _channelName = 'Focus Timer';
  static const String _taskChannelId = 'task_reminders';
  static const String _taskChannelName = 'Task Reminders';
  static const String _scheduledTaskIdsKey = 'scheduled_task_notification_ids';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<FocusNotificationAction> _actionController =
      StreamController<FocusNotificationAction>.broadcast();

  bool _isInitialized = false;
  bool _timeZoneInitialized = false;

  Stream<FocusNotificationAction> get actions => _actionController.stream;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!_isAndroid) return;

    _initializeTimeZone();

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

  Future<void> configureTimeZone(String? timeZoneName) async {
    if (!_isAndroid) return;
    _initializeTimeZone();

    if (timeZoneName == null || timeZoneName.trim().isEmpty) {
      return;
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Ignore invalid backend timezone values and keep the current local zone.
    }
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

  Future<void> showSegmentStarted({
    required String taskTitle,
    required String segmentLabel,
    required String remainingTime,
    required bool isBreak,
  }) async {
    await _show(
      title: isBreak
          ? 'Break Time - $remainingTime'
          : '$segmentLabel - $remainingTime',
      body: isBreak
          ? '$taskTitle - Take a short break before the next focus session.'
          : '$taskTitle - $segmentLabel is now running.',
      ongoing: true,
      actions: isBreak
          ? null
          : const [
              AndroidNotificationAction(
                pauseActionId,
                'Pause',
                showsUserInterface: true,
              ),
            ],
    );
  }

  Future<void> cancel() async {
    if (!_isInitialized) return;
    await _notifications.cancel(id: _notificationId);
  }

  Future<void> scheduleTaskReminders(List<FocusTask> tasks) async {
    if (!_isInitialized) return;

    await _cancelScheduledTaskReminders();

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) return;

    final now = DateTime.now();
    final scheduledIds = <int>{};

    for (final task in tasks) {
      if (_shouldSkipTaskReminder(task, now)) continue;

      final reminders = _buildTaskReminderPayloads(task, now);
      for (final reminder in reminders) {
        final notificationId = _notificationIdForTask(
          taskId: task.id,
          slot: reminder.slot,
        );

        await _notifications.zonedSchedule(
          id: notificationId,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _taskChannelId,
              _taskChannelName,
              channelDescription:
                  'Reminds you before a task starts or reaches its deadline.',
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'task_${task.id}',
        );
        scheduledIds.add(notificationId);
      }
    }

    await _storeScheduledTaskIds(scheduledIds);
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

  void _initializeTimeZone() {
    if (_timeZoneInitialized) return;
    tz.initializeTimeZones();
    _timeZoneInitialized = true;
  }

  bool _shouldSkipTaskReminder(FocusTask task, DateTime now) {
    if (task.isCompleted) return true;
    if (task.repeat == TaskRepeat.none) {
      final daysDifference = _dateOnly(task.scheduledDate)
          .difference(_dateOnly(now))
          .inDays;
      return daysDifference < 0 || daysDifference > 1;
    }

    return !task.occursOn(now);
  }

  List<_TaskReminderPayload> _buildTaskReminderPayloads(
    FocusTask task,
    DateTime now,
  ) {
    final occurrenceDate = _resolveReminderDate(task, now);
    final payloads = <_TaskReminderPayload>[];
    final usedKeys = <String>{};

    void addReminder(
      int slot,
      DateTime? when,
      String title,
      String body,
    ) {
      if (when == null || !when.isAfter(now)) return;
      final key = '${when.toIso8601String()}|$slot';
      if (!usedKeys.add(key)) return;
      payloads.add(
        _TaskReminderPayload(
          slot: slot,
          when: when,
          title: title,
          body: body,
        ),
      );
    }

    final startAt = _combineDateAndClock(occurrenceDate, task.startTime);
    final reminderAt = task.reminderEnabled
        ? _combineDateAndClock(occurrenceDate, task.reminderTime)
        : null;
    final deadlineAt =
        task.deadline ??
        _combineDateAndClock(occurrenceDate, task.endTime) ??
        _combineDateAndClock(occurrenceDate, '23:00:00');

    addReminder(
      1,
      reminderAt ?? startAt?.subtract(const Duration(minutes: 10)),
      'Task starts soon',
      '${task.title} is coming up. Open Focus Time when you are ready.',
    );
    addReminder(
      2,
      deadlineAt?.subtract(const Duration(minutes: 10)),
      'Task almost reaches deadline',
      '${task.title} is still not done and is close to its deadline.',
    );
    addReminder(
      3,
      deadlineAt,
      'Deadline reached',
      '${task.title} reached its deadline, but you can still finish it later today and keep today\'s stats.',
    );

    payloads.sort((first, second) => first.when.compareTo(second.when));
    return payloads;
  }

  DateTime _resolveReminderDate(FocusTask task, DateTime now) {
    if (task.repeat == TaskRepeat.none) {
      return task.scheduledDate;
    }

    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _combineDateAndClock(DateTime date, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    if (hour == null || minute == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      second,
    );
  }

  int _notificationIdForTask({
    required String taskId,
    required int slot,
  }) {
    final stableHash = taskId.codeUnits.fold<int>(
      17,
      (value, codeUnit) => (value * 31 + codeUnit) & 0x7fffffff,
    );
    return 200000 + (stableHash % 100000) + (slot * 100000);
  }

  Future<void> _cancelScheduledTaskReminders() async {
    final scheduledIds = await _loadScheduledTaskIds();
    for (final id in scheduledIds) {
      await _notifications.cancel(id: id);
    }
    await _storeScheduledTaskIds(const <int>{});
  }

  Future<Set<int>> _loadScheduledTaskIds() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_scheduledTaskIdsKey) ?? const [];
    return values
        .map((item) => int.tryParse(item))
        .whereType<int>()
        .toSet();
  }

  Future<void> _storeScheduledTaskIds(Set<int> ids) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _scheduledTaskIdsKey,
      ids.map((item) => item.toString()).toList(),
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _TaskReminderPayload {
  const _TaskReminderPayload({
    required this.slot,
    required this.when,
    required this.title,
    required this.body,
  });

  final int slot;
  final DateTime when;
  final String title;
  final String body;
}
