enum TaskPriority { high, medium, low }

enum FocusTaskStatus { todo, processing, completed }

enum TaskRepeat { none, daily, weekly, monthly }

class FocusOutput {
  FocusOutput({
    this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.sortOrder = 0,
  });

  final int? id;
  final String title;
  bool isCompleted;
  DateTime? completedAt;
  final int sortOrder;

  factory FocusOutput.fromJson(Map<String, dynamic> json) {
    return FocusOutput(
      id: json['id'],
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt']),
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toUpdateJson(int index) {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'sortOrder': index,
    };
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
    this.startTime,
    this.endTime,
    this.repeat = TaskRepeat.none,
    this.reminderEnabled = false,
    this.reminderTime = '09:00:00',
    this.syncToGoogleCalendar = false,
    this.status = FocusTaskStatus.todo,
    this.completedAt,
    this.completionDates = const [],
  }) : scheduledDate = scheduledDate ?? DateTime.now();

  final String id;
  String title;
  String description;
  int focusMinutes;
  TaskPriority priority;
  List<FocusOutput> outputs;
  DateTime scheduledDate;
  DateTime? deadline;
  String? startTime;
  String? endTime;
  TaskRepeat repeat;
  bool reminderEnabled;
  String reminderTime;
  bool syncToGoogleCalendar;
  FocusTaskStatus status;
  DateTime? completedAt;
  List<DateTime> completionDates;

  factory FocusTask.fromJson(Map<String, dynamic> json) {
    final task = FocusTask(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      focusMinutes: json['focusMinutes'] ?? 25,
      priority: _priorityFromString(json['priority']),
      status: _statusFromString(json['status']),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline']),
      scheduledDate: json['scheduledDate'] == null
          ? DateTime.now()
          : DateTime.parse(json['scheduledDate']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      repeat: _repeatFromString(json['repeat']),
      reminderEnabled: json['reminderEnabled'] ?? false,
      reminderTime: json['reminderTime'] ?? '09:00:00',
      syncToGoogleCalendar: json['syncToGoogleCalendar'] ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt']),
      completionDates: ((json['completionDates'] ?? []) as List)
          .map((item) => DateTime.parse(item.toString()))
          .toList(),
      outputs: ((json['outputs'] ?? []) as List)
          .map((item) => FocusOutput.fromJson(item))
          .toList(),
    );

    if (task.repeat != TaskRepeat.none && !task.isCompletedOn(DateTime.now())) {
      for (final output in task.outputs) {
        output.isCompleted = false;
        output.completedAt = null;
      }
    }

    return task;
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'focusMinutes': focusMinutes,
      'priority': _priorityToBackend(priority),
      'deadline': (deadline ?? scheduledDate).toIso8601String(),
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

  Map<String, dynamic> toUpdateJson({DateTime? occurrenceDate}) {
    return {
      'title': title,
      'description': description,
      'focusMinutes': focusMinutes,
      'priority': _priorityToBackend(priority),
      'deadline': (deadline ?? scheduledDate).toIso8601String(),
      'status': _statusToBackend(status),
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'repeat': _repeatToBackend(repeat),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'syncToGoogleCalendar': syncToGoogleCalendar,
      'occurrenceDate': occurrenceDate?.toIso8601String(),
      'outputs': [
        for (var index = 0; index < outputs.length; index++)
          outputs[index].toUpdateJson(index),
      ],
    };
  }

  Map<String, dynamic> toSnapshotJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'focusMinutes': focusMinutes,
      'priority': _priorityToBackend(priority),
      'deadline': deadline?.toIso8601String(),
      'scheduledDate': scheduledDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'repeat': _repeatToBackend(repeat),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'syncToGoogleCalendar': syncToGoogleCalendar,
      'status': _statusToBackend(status),
      'completedAt': completedAt?.toIso8601String(),
      'completionDates':
          completionDates.map((item) => item.toIso8601String()).toList(),
      'outputs': [
        for (var index = 0; index < outputs.length; index++)
          outputs[index].toUpdateJson(index),
      ],
    };
  }

  int get completedOutputCount {
    return outputs.where((output) => output.isCompleted).length;
  }

  bool get isCompleted => isCompletedOn(DateTime.now());

  bool isCompletedOn(DateTime date) {
    if (repeat == TaskRepeat.none) {
      return status == FocusTaskStatus.completed;
    }

    final targetDate = _dateOnly(date);
    return completionDates.any(
      (completedDate) => _isSameDate(_dateOnly(completedDate), targetDate),
    );
  }

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
