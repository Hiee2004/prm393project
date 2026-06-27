enum TaskPriority { high, medium, low }

enum FocusTaskStatus { todo, processing, completed }

enum TaskRepeat { none, daily, weekly, monthly }

class FocusOutput {
  FocusOutput({required this.title, this.isCompleted = false});

  final String title;
  bool isCompleted;
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
    this.repeat = TaskRepeat.none,
    this.reminderEnabled = false,
    this.reminderTime = '09:00',
    this.status = FocusTaskStatus.todo,
  }) : scheduledDate = scheduledDate ?? DateTime.now();

  final String id;
  String title;
  String description;
  int focusMinutes;
  TaskPriority priority;
  List<FocusOutput> outputs;
  DateTime scheduledDate;
  TaskRepeat repeat;
  bool reminderEnabled;
  String reminderTime;
  FocusTaskStatus status;

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
