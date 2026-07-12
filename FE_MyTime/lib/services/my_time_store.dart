import 'package:flutter/foundation.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/models/user_profile.dart';
import 'package:project/models/user_setting.dart';
import 'package:project/services/focus_task_api_service.dart';
import 'package:project/services/settings_api_service.dart';
import 'package:project/services/session_store.dart';
import 'package:project/models/focus_session.dart';
import 'package:project/services/focus_session_api_service.dart';
import 'dart:async';

class MyTimeStore extends ChangeNotifier {
  MyTimeStore._();

  static final MyTimeStore instance = MyTimeStore._();
  final ValueNotifier<String> _themeModeNotifier = ValueNotifier<String>(
    AppTheme.lunarNewYear,
  );

  List<FocusTask> _tasks = [];
  List<FocusSession> _focusSessions = [];
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

  FocusSession? get latestFocusSession {
    return _focusSessions.isEmpty ? null : _focusSessions.first;
  }

  int get totalBackendFocusSeconds {
    return _focusSessions.fold(
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

    notifyListeners();
  }

  UserSetting get setting => _setting;
  ValueListenable<String> get themeModeListenable => _themeModeNotifier;

  void updateSetting(UserSetting setting) {
    final themeChanged = _setting.themeMode != setting.themeMode;
    _setting = setting;
    _profile = _profile.copyWith(
      timeZone: setting.timeZone,
      themeMode: setting.themeMode,
    );
    if (themeChanged) {
      _themeModeNotifier.value = setting.themeMode;
    }
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
    final themeChanged = _profile.themeMode != profile.themeMode;
    _profile = profile;
    _setting = _setting.copyWith(
      timeZone: profile.timeZone,
      themeMode: profile.themeMode,
    );
    if (themeChanged) {
      _themeModeNotifier.value = profile.themeMode;
    }
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
      notifyListeners();
      return createdTask;
    }

    _tasks.add(task);
    _selectedTask = task;
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
  }) async {
    final oldOutputs = {
      for (final output in task.outputs) output.title: output.isCompleted,
    };

    task.title = title;
    task.description = description;
    task.focusMinutes = focusMinutes;
    task.priority = priority;
    task.scheduledDate = scheduledDate;
    task.repeat = repeat;
    task.reminderEnabled = reminderEnabled;
    task.reminderTime = reminderTime;
    task.outputs = outputs
        .map(
          (outputTitle) => FocusOutput(
            title: outputTitle,
            isCompleted: oldOutputs[outputTitle] ?? false,
          ),
        )
        .toList();
    task.status = status;

    if (status == FocusTaskStatus.completed) {
      for (final output in task.outputs) {
        output.isCompleted = true;
      }
      task.completedAt ??= DateTime.now();
    } else if (task.outputs.every((output) => output.isCompleted)) {
      for (final output in task.outputs) {
        output.isCompleted = false;
      }
      task.completedAt = null;
    }

    final token = SessionStore.instance.token;
    if (token != null && token.isNotEmpty) {
      final updatedTask = await FocusTaskApiService.instance.updateTask(
        token: token,
        task: task,
      );
      _syncTaskFromRemote(task, updatedTask);
    }

    if (task.isCompleted && identical(_selectedTask, task)) {
      _selectedTask = _firstPlannedTask;
    }

    notifyListeners();
  }

  Future<void> setTaskCompleted(FocusTask task, bool completed) async {
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
      notifyListeners();
      rethrow;
    }
  }

  FocusSessionResult completeSession({
    required FocusTask task,
    required int elapsedSeconds,
    required Set<int> completedIndexes,
    required int distractions,
  }) {
    for (var index = 0; index < task.outputs.length; index++) {
      if (completedIndexes.contains(index)) {
        task.outputs[index].isCompleted = true;
      }
    }

    if (task.outputs.every((output) => output.isCompleted)) {
      task.status = FocusTaskStatus.completed;
      task.completedAt = DateTime.now();
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
      plannedMinutes: task.focusMinutes,
      elapsedSeconds: elapsedSeconds,
      completedOutputs: completedTitles.length,
      totalOutputs: task.outputs.length,
      completedOutputTitles: completedTitles,
      unfinishedOutputTitles: unfinishedTitles,
      distractions: distractions,
      finishedAt: DateTime.now(),
    );

    _sessions.add(result);
    if (task.isCompleted && identical(_selectedTask, task)) {
      _selectedTask = _firstPlannedTask;
    }
    unawaited(loadSessionsFromApi());
    notifyListeners();
    return result;
  }

  void _syncTaskFromRemote(FocusTask target, FocusTask source) {
    target.title = source.title;
    target.description = source.description;
    target.focusMinutes = source.focusMinutes;
    target.priority = source.priority;
    target.outputs = source.outputs;
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
}
