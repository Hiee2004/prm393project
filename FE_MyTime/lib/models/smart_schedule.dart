class SmartScheduledTask {
  const SmartScheduledTask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.sessionNumber,
    required this.estimatedMinutes,
    required this.difficulty,
    required this.priorityScore,
    required this.aiScore,
    required this.isOverlapping,
  });

  final int id;
  final int taskId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int sessionNumber;
  final int estimatedMinutes;
  final int difficulty;
  final int priorityScore;
  final double aiScore;
  final bool isOverlapping;

  Duration get duration => endTime.difference(startTime);

  factory SmartScheduledTask.fromJson(Map<String, dynamic> json) {
    return SmartScheduledTask(
      id: json['id'] as int,
      taskId: json['taskId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      startTime: _parseScheduledDateTime(json['startTime']),
      endTime: _parseScheduledDateTime(json['endTime']),
      sessionNumber: json['sessionNumber'] as int? ?? 1,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 25,
      difficulty: json['difficulty'] as int? ?? 3,
      priorityScore: json['priorityScore'] as int? ?? 0,
      aiScore: (json['aiScore'] as num?)?.toDouble() ?? 0,
      isOverlapping: json['isOverlapping'] as bool? ?? false,
    );
  }

  SmartScheduledTask copyWith({
    DateTime? startTime,
    DateTime? endTime,
    bool? isOverlapping,
  }) {
    return SmartScheduledTask(
      id: id,
      taskId: taskId,
      title: title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionNumber: sessionNumber,
      estimatedMinutes: estimatedMinutes,
      difficulty: difficulty,
      priorityScore: priorityScore,
      aiScore: aiScore,
      isOverlapping: isOverlapping ?? this.isOverlapping,
    );
  }
}

class SmartSchedulePlan {
  const SmartSchedulePlan({
    required this.generatedAt,
    required this.dailySuggestion,
    required this.suggestedTaskOrder,
    required this.scheduledTasks,
  });

  final DateTime generatedAt;
  final String dailySuggestion;
  final List<Map<String, dynamic>> suggestedTaskOrder;
  final List<SmartScheduledTask> scheduledTasks;

  factory SmartSchedulePlan.fromJson(Map<String, dynamic> json) {
    return SmartSchedulePlan(
      generatedAt: _parseScheduledDateTime(json['generatedAt']),
      dailySuggestion: json['dailySuggestion'] as String? ?? '',
      suggestedTaskOrder: ((json['suggestedTaskOrder'] ?? []) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      scheduledTasks: ((json['scheduledTasks'] ?? []) as List)
          .map(
            (item) => SmartScheduledTask.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

DateTime _parseScheduledDateTime(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) {
    return DateTime.now();
  }

  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?',
  ).firstMatch(text);

  if (match == null) {
    return DateTime.tryParse(text)?.toLocal() ?? DateTime.now();
  }

  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6) ?? '0'),
  );
}

class DailyScheduleSuggestion {
  const DailyScheduleSuggestion({
    required this.suggestion,
    required this.highlightTaskTitle,
    required this.highlightScore,
  });

  final String suggestion;
  final String? highlightTaskTitle;
  final double? highlightScore;

  factory DailyScheduleSuggestion.fromJson(Map<String, dynamic> json) {
    return DailyScheduleSuggestion(
      suggestion: json['suggestion'] as String? ?? '',
      highlightTaskTitle: json['highlightTaskTitle'] as String?,
      highlightScore: (json['highlightScore'] as num?)?.toDouble(),
    );
  }
}
