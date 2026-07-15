import 'package:flutter/foundation.dart';
import 'package:project/models/app_notification.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/models/user_profile.dart';
import 'package:project/models/user_setting.dart';
import 'package:project/services/focus_task_api_service.dart';
import 'package:project/services/focus_notification_service.dart';
import 'package:project/services/notification_api_service.dart';
import 'package:project/services/settings_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/models/focus_session.dart';
import 'package:project/services/focus_session_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class MyTimeStore extends ChangeNotifier {
  MyTimeStore._();

  static const _themePreferenceKey = 'mytime_theme_mode';

  static final MyTimeStore instance = MyTimeStore._();
  final ValueNotifier<String> _themeModeNotifier = ValueNotifier<String>(
    AppTheme.lunarNewYear,
  );

  List<FocusTask> _tasks = [];
  List<FocusSession> _focusSessions = [];
  List<AppNotification> _notifications = [];
  UserSetting _setting = const UserSetting(
    defaultFocusMinutes: 25,
    notificationEnabled: true,
    autoSyncGoogleCalendar: false,
    dailyReviewEnabled: true,
    dailyReviewTime: '21:00:00',
    preferredFocusStartTime: '08:00:00',
    preferredFocusEndTime: '22:00:00',
    timeZone: 'Asia/Ho_Chi_Minh',
    themeMode: AppTheme.lunarNewYear,
  );

  Future<void> loadSessionsFromApi() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final sessions = await FocusSessionApiService.instance.getSessions(token);

    _focusSessions = sessions;

    notifyListeners();
  }

  List<FocusSession> get focusSessions => List.unmodifiable(_focusSessions);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  FocusSession? get latestFocusSession {
    return _focusSessions.isEmpty ? null : _focusSessions.first;
  }

  int get totalBackendFocusSeconds {
    return _focusSessions.fold(
      0,
      (total, session) => total + session.actualFocusSeconds,
    );
  }

  List<FocusSession> focusSessionsForDate(DateTime date) {
    final targetDate = _dateOnly(date);
    return _focusSessions.where((session) {
      final sessionDate = _dateOnly(
        (session.completedAt ?? session.startedAt).toLocal(),
      );
      return sessionDate == targetDate;
    }).toList();
  }

  int totalBackendFocusSecondsForDate(DateTime date) {
    return focusSessionsForDate(date).fold(
      0,
      (total, session) => total + session.actualFocusSeconds,
    );
  }

  int get totalBackendCompletedOutputs {
    return _focusSessions.fold(
      0,
      (total, session) => total + session.completedOutputs,
    );
  }

  Future<void> loadTasksFromApi() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final tasks = await FocusTaskApiService.instance.getTasks(token);

    _tasks = tasks;
    _selectedTask = _firstPlannedTask;

    unawaited(_refreshTaskReminders());
    notifyListeners();
  }

  Future<void> loadNotificationsFromApi() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final notifications = await NotificationApiService.instance.getNotifications(
      token,
    );
    _notifications = notifications;
    notifyListeners();
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final updated = await NotificationApiService.instance.markAsRead(
      token: token,
      notificationId: notificationId,
    );

    final index = _notifications.indexWhere((item) => item.id == notificationId);
    if (index >= 0) {
      _notifications[index] = updated;
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    await NotificationApiService.instance.markAllAsRead(token);
    _notifications = _notifications
        .map(
          (item) => AppNotification(
            id: item.id,
            title: item.title,
            message: item.message,
            type: item.type,
            isRead: true,
            createdAt: item.createdAt,
            focusTaskId: item.focusTaskId,
            scheduledAt: item.scheduledAt,
            sentAt: item.sentAt,
          ),
        )
        .toList();
    notifyListeners();
  }

  UserSetting get setting => _setting;
  ValueListenable<String> get themeModeListenable => _themeModeNotifier;

  Future<void> hydrateThemeFromLocal() async {
    final preferences = await SharedPreferences.getInstance();
    final storedTheme = preferences.getString(_themePreferenceKey);
    if (storedTheme == null || storedTheme.trim().isEmpty) return;

    final normalizedTheme = AppTheme.normalizeMode(storedTheme);
    _themeModeNotifier.value = normalizedTheme;
    _setting = _setting.copyWith(themeMode: normalizedTheme);
    _profile = _profile.copyWith(themeMode: normalizedTheme);
    notifyListeners();
  }

  void updateSetting(UserSetting setting) {
    final normalizedTheme = AppTheme.normalizeMode(setting.themeMode);
    final themeChanged = _setting.themeMode != normalizedTheme;
    _setting = setting.copyWith(themeMode: normalizedTheme);
    _profile = _profile.copyWith(
      timeZone: setting.timeZone,
      themeMode: normalizedTheme,
    );
    if (themeChanged) {
      _themeModeNotifier.value = normalizedTheme;
    }
    unawaited(FocusNotificationService.instance.configureTimeZone(setting.timeZone));
    unawaited(_refreshTaskReminders());
    unawaited(_persistThemeMode(normalizedTheme));
    notifyListeners();
  }

  Future<void> hydrateSettingsFromBackend() async {
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final remoteSetting = await SettingsApiService.instance.getSettings(token);
    updateSetting(remoteSetting);
  }

  final List<FocusSessionResult> _sessions = [];
  FocusTask? _selectedTask;
  DateTime _selectedCalendarDate = DateTime.now();

  List<FocusTask> get tasks => List.unmodifiable(_tasks);

  List<FocusSessionResult> get sessions => List.unmodifiable(_sessions);

  List<FocusTask> tasksForDate(DateTime date) {
    return _tasks.where((task) => task.occursOn(date)).toList();
  }

  DateTime get selectedCalendarDate => _selectedCalendarDate;

  void updateSelectedCalendarDate(DateTime date) {
    _selectedCalendarDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  FocusTask? get selectedTask {
    final selected = _selectedTask;
    if (selected == null) return _firstPlannedTask;
    if (selected.isCompleted || !selected.canStartToday) {
      return _firstPlannedTask;
    }
    return selected;
  }

  FocusTask? get _firstPlannedTask {
    for (final task in _tasks) {
      if (!task.isCompleted && task.canStartToday) return task;
    }
    return null;
  }

  FocusSessionResult? get latestSession {
    return _sessions.isEmpty ? null : _sessions.last;
  }

  int get totalFocusSeconds {
    return _sessions.fold(
      0,
      (total, session) => total + session.elapsedSeconds,
    );
  }

  int get totalCompletedOutputs {
    return _tasks.fold(0, (total, task) => total + task.completedOutputCount);
  }

  int get completedTaskCount {
    return _tasks.where((task) => task.isCompleted).length;
  }

  int completedTaskCountForDate(DateTime date) {
    return tasksForDate(date).where((task) => task.isCompletedOn(date)).length;
  }

  void selectTask(FocusTask task) {
    _selectedTask = task;
    notifyListeners();
  }

  bool startTask(FocusTask task) {
    if (!task.canStartToday) {
      _selectedTask = task;
      notifyListeners();
      return false;
    }

    _selectedTask = task;
    if (!task.isCompleted) {
      task.status = FocusTaskStatus.processing;
    }
    notifyListeners();
    return true;
  }

  UserProfile _profile = const UserProfile(
    fullName: 'Thu',
    email: 'thu@example.com',
    avatarUrl: null,
    themeMode: AppTheme.lunarNewYear,
  );

  UserProfile get profile => _profile;

  void updateProfile(UserProfile profile) {
    final normalizedTheme = AppTheme.normalizeMode(profile.themeMode);
    final themeChanged = _profile.themeMode != normalizedTheme;
    _profile = profile.copyWith(themeMode: normalizedTheme);
    _setting = _setting.copyWith(
      timeZone: profile.timeZone,
      themeMode: normalizedTheme,
    );
    if (themeChanged) {
      _themeModeNotifier.value = normalizedTheme;
    }
    unawaited(_persistThemeMode(normalizedTheme));
    notifyListeners();
  }

  Future<void> _persistThemeMode(String themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, themeMode);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void upsertTaskFromApi(FocusTask updatedTask) {
    final existingIndex = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (existingIndex >= 0) {
      _tasks[existingIndex] = updatedTask;
    } else {
      _tasks.add(updatedTask);
    }

    if (_selectedTask?.id == updatedTask.id) {
      _selectedTask = updatedTask;
    }

    unawaited(_refreshTaskReminders());
    notifyListeners();
  }

  Future<FocusTask> addTask({
    required String title,
    required String description,
    required int focusMinutes,
    required TaskPriority priority,
    required List<String> outputs,
    DateTime? scheduledDate,
    TaskRepeat repeat = TaskRepeat.none,
    bool reminderEnabled = false,
    String reminderTime = '09:00:00',
  }) async {
    final task = FocusTask(
      id: '0',
      title: title,
      description: description,
      focusMinutes: focusMinutes,
      priority: priority,
      scheduledDate: scheduledDate,
      repeat: repeat,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
      outputs: outputs.map((title) => FocusOutput(title: title)).toList(),
    );

    final token = SessionStore.instance.token;

    if (token != null && token.isNotEmpty) {
      final createdTask = await FocusTaskApiService.instance.createTask(
        token: token,
        task: task,
      );

      _tasks.add(createdTask);
      _selectedTask = createdTask;
      unawaited(_refreshTaskReminders());
      notifyListeners();
      return createdTask;
    }

    _tasks.add(task);
    _selectedTask = task;
    unawaited(_refreshTaskReminders());
    notifyListeners();
    return task;
  }

  Future<void> updateTask({
    required FocusTask task,
    required String title,
    required String description,
    required int focusMinutes,
    required TaskPriority priority,
    required FocusTaskStatus status,
    required List<String> outputs,
    required DateTime scheduledDate,
    required TaskRepeat repeat,
    required bool reminderEnabled,
    required String reminderTime,
    DateTime? occurrenceDate,
  }) async {
    final existingOutputs = List<FocusOutput>.from(task.outputs);

    task.title = title;
    task.description = description;
    task.focusMinutes = focusMinutes;
    task.priority = priority;
    task.scheduledDate = scheduledDate;
    task.repeat = repeat;
    task.reminderEnabled = reminderEnabled;
    task.reminderTime = reminderTime;
    task.outputs = outputs
        .asMap()
        .entries
        .map(
          (entry) {
            final index = entry.key;
            final outputTitle = entry.value;
            final previous = index < existingOutputs.length
                ? existingOutputs[index]
                : null;

            return FocusOutput(
              id: previous?.id,
              title: outputTitle,
              isCompleted: previous?.isCompleted ?? false,
              completedAt: previous?.completedAt,
              sortOrder: index,
            );
          },
        )
        .toList();
    task.status = status;

    if (status == FocusTaskStatus.completed) {
      for (final output in task.outputs) {
        output.isCompleted = true;
        output.completedAt ??= DateTime.now();
      }
      task.completedAt ??= DateTime.now();
    } else if (task.outputs.every((output) => output.isCompleted)) {
      for (final output in task.outputs) {
        output.isCompleted = false;
        output.completedAt = null;
      }
      task.completedAt = null;
    }

    final token = SessionStore.instance.token;
    if (token != null && token.isNotEmpty) {
      final updatedTask = await FocusTaskApiService.instance.updateTask(
        token: token,
        task: task,
        occurrenceDate: occurrenceDate,
      );
      _syncTaskFromRemote(task, updatedTask);
    }

    if (task.isCompleted && identical(_selectedTask, task)) {
      _selectedTask = _firstPlannedTask;
    }

    unawaited(_refreshTaskReminders());
    notifyListeners();
  }

  Future<void> setTaskCompleted(
    FocusTask task,
    bool completed, {
    DateTime? occurrenceDate,
  }) async {
    await updateTask(
      task: task,
      title: task.title,
      description: task.description,
      focusMinutes: task.focusMinutes,
      priority: task.priority,
      status: completed ? FocusTaskStatus.completed : FocusTaskStatus.todo,
      outputs: task.outputs.map((output) => output.title).toList(),
      scheduledDate: task.scheduledDate,
      repeat: task.repeat,
      reminderEnabled: task.reminderEnabled,
      reminderTime: task.reminderTime,
      occurrenceDate: occurrenceDate,
    );
  }

  Future<void> deleteTask(FocusTask task) async {
    final existingIndex = _tasks.indexOf(task);
    if (existingIndex == -1) return;

    final previousSelectedTask = _selectedTask;
    _tasks.removeAt(existingIndex);
    if (identical(_selectedTask, task)) {
      _selectedTask = _firstPlannedTask;
    }
    unawaited(_refreshTaskReminders());
    notifyListeners();

    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await FocusTaskApiService.instance.deleteTask(
        token: token,
        taskId: task.id,
      );
    } catch (error) {
      _tasks.insert(existingIndex, task);
      _selectedTask = previousSelectedTask;
      unawaited(_refreshTaskReminders());
      notifyListeners();
      rethrow;
    }
  }

  Future<FocusSessionResult> completeSession({
    required FocusTask task,
    required int elapsedSeconds,
    required int plannedMinutes,
    required Set<int> completedIndexes,
    required int distractions,
    DateTime? occurrenceDate,
  }) async {
    final now = DateTime.now();

    for (var index = 0; index < task.outputs.length; index++) {
      if (completedIndexes.contains(index)) {
        task.outputs[index].isCompleted = true;
        task.outputs[index].completedAt ??= now;
      }
    }

    if (task.outputs.every((output) => output.isCompleted)) {
      task.status = FocusTaskStatus.completed;
      task.completedAt = now;
    } else {
      task.status = FocusTaskStatus.processing;
      task.completedAt = null;
    }

    final completedTitles = task.outputs
        .where((output) => output.isCompleted)
        .map((output) => output.title)
        .toList();
    final unfinishedTitles = task.outputs
        .where((output) => !output.isCompleted)
        .map((output) => output.title)
        .toList();

    final result = FocusSessionResult(
      taskTitle: task.title,
      plannedMinutes: plannedMinutes,
      elapsedSeconds: elapsedSeconds,
      completedOutputs: completedTitles.length,
      totalOutputs: task.outputs.length,
      completedOutputTitles: completedTitles,
      unfinishedOutputTitles: unfinishedTitles,
      distractions: distractions,
      finishedAt: now,
    );

    _sessions.add(result);

    final token = SessionStore.instance.token;
    if (token != null && token.isNotEmpty) {
      try {
        final updatedTask = await FocusTaskApiService.instance.updateTask(
          token: token,
          task: task,
          occurrenceDate: occurrenceDate,
        );
        _syncTaskFromRemote(task, updatedTask);
      } catch (error) {
        debugPrint('Failed to sync focus task after session: $error');
      }
    }

    if (task.isCompleted && identical(_selectedTask, task)) {
      _selectedTask = _firstPlannedTask;
    }
    unawaited(loadSessionsFromApi());
    unawaited(_refreshTaskReminders());
    notifyListeners();
    return result;
  }

  Future<void> restoreTaskSnapshot(FocusTask snapshot) async {
    final existingIndex = _tasks.indexWhere((task) => task.id == snapshot.id);
    if (existingIndex == -1) return;

    final target = _tasks[existingIndex];
    final previous = FocusTask.fromJson(target.toSnapshotJson());
    _syncTaskFromRemote(target, snapshot);
    target.completionDates = List<DateTime>.from(snapshot.completionDates);

    notifyListeners();

    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) {
      unawaited(_refreshTaskReminders());
      return;
    }

    try {
      final updatedTask = await FocusTaskApiService.instance.updateTask(
        token: token,
        task: target,
      );
      _syncTaskFromRemote(target, updatedTask);
      target.completionDates = List<DateTime>.from(updatedTask.completionDates);
      unawaited(_refreshTaskReminders());
      notifyListeners();
    } catch (error) {
      _syncTaskFromRemote(target, previous);
      target.completionDates = List<DateTime>.from(previous.completionDates);
      notifyListeners();
      rethrow;
    }
  }

  void _syncTaskFromRemote(FocusTask target, FocusTask source) {
    target.title = source.title;
    target.description = source.description;
    target.focusMinutes = source.focusMinutes;
    target.priority = source.priority;
    target.outputs = List<FocusOutput>.from(source.outputs);
    target.scheduledDate = source.scheduledDate;
    target.startTime = source.startTime;
    target.endTime = source.endTime;
    target.repeat = source.repeat;
    target.reminderEnabled = source.reminderEnabled;
    target.reminderTime = source.reminderTime;
    target.syncToGoogleCalendar = source.syncToGoogleCalendar;
    target.status = source.status;
    target.completedAt = source.completedAt;
  }

  Future<void> _refreshTaskReminders() async {
    await FocusNotificationService.instance.scheduleTaskReminders(_tasks);
  }
}
