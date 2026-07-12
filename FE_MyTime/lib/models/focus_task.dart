enum TaskPriority { high, medium, low }

enum FocusTaskStatus { todo, processing, completed }

enum TaskRepeat { none, daily, weekly, monthly }

class FocusOutput {
  FocusOutput({
    this.id,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
  });

  final int? id;
  final String title;
  bool isCompleted;
  final int sortOrder;

  factory FocusOutput.fromJson(Map<String, dynamic> json) {
    return FocusOutput(
      id: json['id'],
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class FocusTask {
  FocusTask({
    required this.id,
    required this.title,
    required this.description,
    required this.focusMinutes,
    required this.priority,
    required this.outputs,
    DateTime? scheduledDate,
    this.deadline,
    this.difficulty = 3,
    this.startTime,
    this.endTime,
    this.repeat = TaskRepeat.none,
    this.reminderEnabled = false,
    this.reminderTime = '09:00:00',
    this.syncToGoogleCalendar = false,
    this.status = FocusTaskStatus.todo,
  }) : scheduledDate = scheduledDate ?? DateTime.now();

  final String id;
  String title;
  String description;
  int focusMinutes;
  TaskPriority priority;
  List<FocusOutput> outputs;
  DateTime scheduledDate;
  DateTime? deadline;
  int difficulty;
  String? startTime;
  String? endTime;
  TaskRepeat repeat;
  bool reminderEnabled;
  String reminderTime;
  bool syncToGoogleCalendar;
  FocusTaskStatus status;

  factory FocusTask.fromJson(Map<String, dynamic> json) {
    return FocusTask(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      focusMinutes: json['focusMinutes'] ?? 25,
      priority: _priorityFromString(json['priority']),
      status: _statusFromString(json['status']),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline']),
      difficulty: json['difficulty'] ?? 3,
      scheduledDate: json['scheduledDate'] == null
          ? DateTime.now()
          : DateTime.parse(json['scheduledDate']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      repeat: _repeatFromString(json['repeat']),
      reminderEnabled: json['reminderEnabled'] ?? false,
      reminderTime: json['reminderTime'] ?? '09:00:00',
      syncToGoogleCalendar: json['syncToGoogleCalendar'] ?? false,
      outputs: ((json['outputs'] ?? []) as List)
          .map((item) => FocusOutput.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'focusMinutes': focusMinutes,
      'priority': _priorityToBackend(priority),
      'deadline': (deadline ?? scheduledDate).toIso8601String(),
      'difficulty': difficulty,
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'repeat': _repeatToBackend(repeat),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'syncToGoogleCalendar': syncToGoogleCalendar,
      'outputs': outputs.map((output) => output.title).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'focusMinutes': focusMinutes,
      'priority': _priorityToBackend(priority),
      'deadline': (deadline ?? scheduledDate).toIso8601String(),
      'difficulty': difficulty,
      'status': _statusToBackend(status),
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'repeat': _repeatToBackend(repeat),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'syncToGoogleCalendar': syncToGoogleCalendar,
      'outputs': outputs.map((output) => output.title).toList(),
    };
  }

  int get completedOutputCount {
    return outputs.where((output) => output.isCompleted).length;
  }

  bool get isCompleted => status == FocusTaskStatus.completed;

  bool get canStartToday => occursOn(DateTime.now());

  bool occursOn(DateTime date) {
    final planDate = _dateOnly(scheduledDate);
    final targetDate = _dateOnly(date);
    if (targetDate.isBefore(planDate)) return false;

    switch (repeat) {
      case TaskRepeat.none:
        return _isSameDate(planDate, targetDate);
      case TaskRepeat.daily:
        return true;
      case TaskRepeat.weekly:
        return planDate.weekday == targetDate.weekday;
      case TaskRepeat.monthly:
        return planDate.day == targetDate.day;
    }
  }
}

TaskPriority _priorityFromString(dynamic value) {
  final text = value?.toString().toLowerCase() ?? 'medium';

  switch (text) {
    case 'high':
      return TaskPriority.high;
    case 'low':
      return TaskPriority.low;
    default:
      return TaskPriority.medium;
  }
}

FocusTaskStatus _statusFromString(dynamic value) {
  final text = value?.toString().toLowerCase() ?? 'todo';

  switch (text) {
    case 'processing':
      return FocusTaskStatus.processing;
    case 'completed':
      return FocusTaskStatus.completed;
    default:
      return FocusTaskStatus.todo;
  }
}

TaskRepeat _repeatFromString(dynamic value) {
  final text = value?.toString().toLowerCase() ?? 'none';

  switch (text) {
    case 'daily':
      return TaskRepeat.daily;
    case 'weekly':
      return TaskRepeat.weekly;
    case 'monthly':
      return TaskRepeat.monthly;
    default:
      return TaskRepeat.none;
  }
}

String _priorityToBackend(TaskPriority value) {
  switch (value) {
    case TaskPriority.high:
      return 'High';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.low:
      return 'Low';
  }
}

String _statusToBackend(FocusTaskStatus value) {
  switch (value) {
    case FocusTaskStatus.todo:
      return 'Todo';
    case FocusTaskStatus.processing:
      return 'Processing';
    case FocusTaskStatus.completed:
      return 'Completed';
  }
}

String _repeatToBackend(TaskRepeat value) {
  switch (value) {
    case TaskRepeat.none:
      return 'None';
    case TaskRepeat.daily:
      return 'Daily';
    case TaskRepeat.weekly:
      return 'Weekly';
    case TaskRepeat.monthly:
      return 'Monthly';
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class FocusSessionResult {
  const FocusSessionResult({
    required this.taskTitle,
    required this.plannedMinutes,
    required this.elapsedSeconds,
    required this.completedOutputs,
    required this.totalOutputs,
    required this.completedOutputTitles,
    required this.unfinishedOutputTitles,
    required this.distractions,
    required this.finishedAt,
  });

  final String taskTitle;
  final int plannedMinutes;
  final int elapsedSeconds;
  final int completedOutputs;
  final int totalOutputs;
  final List<String> completedOutputTitles;
  final List<String> unfinishedOutputTitles;
  final int distractions;
  final DateTime finishedAt;

  int get completionPercent {
    if (totalOutputs == 0) return 0;
    return ((completedOutputs / totalOutputs) * 100).round();
  }
}
