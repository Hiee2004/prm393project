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
    this.segmentLabel,
    this.isBreakSegment = false,
    int? sourceScheduledTaskId,
    this.segmentOffsetMinutes = 0,
    this.isPrimarySegment = true,
    this.planSessionCount = 1,
    this.isFromAppliedPlan = false,
  }) : sourceScheduledTaskId = sourceScheduledTaskId ?? id;

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
  final String? segmentLabel;
  final bool isBreakSegment;
  final int sourceScheduledTaskId;
  final int segmentOffsetMinutes;
  final bool isPrimarySegment;
  final int planSessionCount;
  final bool isFromAppliedPlan;

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
      segmentLabel: json['segmentLabel'] as String?,
      isBreakSegment: json['isBreakSegment'] as bool? ?? false,
      sourceScheduledTaskId: json['sourceScheduledTaskId'] as int?,
      segmentOffsetMinutes: json['segmentOffsetMinutes'] as int? ?? 0,
      isPrimarySegment: json['isPrimarySegment'] as bool? ?? true,
      planSessionCount: json['planSessionCount'] as int? ?? 1,
      isFromAppliedPlan: json['isFromAppliedPlan'] as bool? ?? false,
    );
  }

  SmartScheduledTask copyWith({
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    int? sessionNumber,
    int? estimatedMinutes,
    int? difficulty,
    int? priorityScore,
    double? aiScore,
    bool? isOverlapping,
    String? segmentLabel,
    bool? isBreakSegment,
    int? sourceScheduledTaskId,
    int? segmentOffsetMinutes,
    bool? isPrimarySegment,
    int? planSessionCount,
    bool? isFromAppliedPlan,
  }) {
    return SmartScheduledTask(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficulty: difficulty ?? this.difficulty,
      priorityScore: priorityScore ?? this.priorityScore,
      aiScore: aiScore ?? this.aiScore,
      isOverlapping: isOverlapping ?? this.isOverlapping,
      segmentLabel: segmentLabel ?? this.segmentLabel,
      isBreakSegment: isBreakSegment ?? this.isBreakSegment,
      sourceScheduledTaskId:
          sourceScheduledTaskId ?? this.sourceScheduledTaskId,
      segmentOffsetMinutes: segmentOffsetMinutes ?? this.segmentOffsetMinutes,
      isPrimarySegment: isPrimarySegment ?? this.isPrimarySegment,
      planSessionCount: planSessionCount ?? this.planSessionCount,
      isFromAppliedPlan: isFromAppliedPlan ?? this.isFromAppliedPlan,
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
