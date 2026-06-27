import 'package:flutter/foundation.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/models/user_profile.dart';

class MyTimeStore extends ChangeNotifier {
  MyTimeStore._();

  static final MyTimeStore instance = MyTimeStore._();

  final List<FocusTask> _tasks = [
    FocusTask(
      id: 'task-1',
      title: 'Complete the MyTime interface',
      description: 'Finish the Focus Time flow and test navigation.',
      focusMinutes: 25,
      priority: TaskPriority.high,
      outputs: [
        FocusOutput(title: 'Complete the Focus Time screen'),
        FocusOutput(title: 'Test the start and pause buttons'),
        FocusOutput(title: 'Test the results screen'),
      ],
    ),
    FocusTask(
      id: 'task-2',
      title: 'Write the project report',
      description: 'Describe the application goals, features, and results.',
      focusMinutes: 45,
      priority: TaskPriority.medium,
      outputs: [
        FocusOutput(title: 'Write the system goals'),
        FocusOutput(title: 'Describe the Focus Time flow'),
        FocusOutput(title: 'Capture application screenshots'),
      ],
    ),
  ];

  final List<FocusSessionResult> _sessions = [];
  FocusTask? _selectedTask;

  List<FocusTask> get tasks => List.unmodifiable(_tasks);

  List<FocusSessionResult> get sessions => List.unmodifiable(_sessions);

  List<FocusTask> tasksForDate(DateTime date) {
    return _tasks.where((task) => task.occursOn(date)).toList();
  }

  FocusTask? get selectedTask {
    return _selectedTask ?? _firstPlannedTask;
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
    themeMode: 'Yellow',
  );

  UserProfile get profile => _profile;

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  FocusTask addTask({
    required String title,
    required String description,
    required int focusMinutes,
    required TaskPriority priority,
    required List<String> outputs,
    DateTime? scheduledDate,
    TaskRepeat repeat = TaskRepeat.none,
    bool reminderEnabled = false,
    String reminderTime = '09:00',
  }) {
    final task = FocusTask(
      id: 'task-${DateTime.now().microsecondsSinceEpoch}',
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

    _tasks.add(task);
    _selectedTask = task;
    notifyListeners();
    return task;
  }

  void updateTask({
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
  }) {
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
    } else if (task.outputs.every((output) => output.isCompleted)) {
      for (final output in task.outputs) {
        output.isCompleted = false;
      }
    }

    notifyListeners();
  }

  void deleteTask(FocusTask task) {
    _tasks.remove(task);
    if (identical(_selectedTask, task)) {
      _selectedTask = _firstPlannedTask;
    }
    notifyListeners();
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
    } else {
      task.status = FocusTaskStatus.processing;
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
    notifyListeners();
    return result;
  }
}
