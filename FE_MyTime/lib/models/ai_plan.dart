class AiTaskScore {
  const AiTaskScore({
    required this.id,
    required this.title,
    required this.description,
    required this.focusMinutes,
    required this.priority,
    required this.status,
    required this.scheduledDate,
    required this.aiScore,
    required this.scoreReasons,
  });

  final int id;
  final String title;
  final String? description;
  final int focusMinutes;
  final String priority;
  final String status;
  final DateTime? scheduledDate;
  final double aiScore;
  final List<String> scoreReasons;

  factory AiTaskScore.fromJson(Map<String, dynamic> json) {
    return AiTaskScore(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      focusMinutes: json['focusMinutes'] as int? ?? 25,
      priority: json['priority'] as String? ?? '',
      status: json['status'] as String? ?? '',
      scheduledDate: json['scheduledDate'] == null
          ? null
          : DateTime.parse(json['scheduledDate'] as String),
      aiScore: (json['aiScore'] as num?)?.toDouble() ?? 0,
      scoreReasons: ((json['scoreReasons'] ?? []) as List)
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AiPlanDraftModel {
  const AiPlanDraftModel({
    required this.id,
    required this.taskId,
    required this.suggestedTitle,
    required this.suggestedDate,
    required this.suggestedStartTime,
    required this.suggestedEndTime,
    required this.suggestedFocusMinutes,
    required this.reason,
    required this.suggestedOutputsJson,
    required this.createdAt,
  });

  final int id;
  final int taskId;
  final String suggestedTitle;
  final DateTime suggestedDate;
  final String suggestedStartTime;
  final String suggestedEndTime;
  final int suggestedFocusMinutes;
  final String reason;
  final String suggestedOutputsJson;
  final DateTime createdAt;

  factory AiPlanDraftModel.fromJson(Map<String, dynamic> json) {
    return AiPlanDraftModel(
      id: json['id'] as int,
      taskId: json['taskId'] as int? ?? 0,
      suggestedTitle: json['suggestedTitle'] as String? ?? '',
      suggestedDate: DateTime.parse(json['suggestedDate'] as String),
      suggestedStartTime: json['suggestedStartTime'] as String? ?? '08:00:00',
      suggestedEndTime: json['suggestedEndTime'] as String? ?? '08:25:00',
      suggestedFocusMinutes: json['suggestedFocusMinutes'] as int? ?? 25,
      reason: json['reason'] as String? ?? '',
      suggestedOutputsJson: json['suggestedOutputsJson'] as String? ?? '[]',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AiPomodoroSession {
  const AiPomodoroSession({
    required this.taskId,
    required this.taskTitle,
    required this.sessionNumber,
    required this.durationMinutes,
    required this.isBreak,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
  });

  final int taskId;
  final String taskTitle;
  final int sessionNumber;
  final int durationMinutes;
  final bool isBreak;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;

  factory AiPomodoroSession.fromJson(Map<String, dynamic> json) {
    return AiPomodoroSession(
      taskId: json['taskId'] as int? ?? 0,
      taskTitle: json['taskTitle'] as String? ?? '',
      sessionNumber: json['sessionNumber'] as int? ?? 1,
      durationMinutes: json['durationMinutes'] as int? ?? 25,
      isBreak: json['isBreak'] as bool? ?? false,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      startTime: json['startTime'] as String? ?? '08:00:00',
      endTime: json['endTime'] as String? ?? '08:25:00',
    );
  }
}

class AiDailySuggestion {
  const AiDailySuggestion({
    required this.suggestion,
    required this.highlightTaskTitle,
    required this.highlightScore,
  });

  final String suggestion;
  final String? highlightTaskTitle;
  final double? highlightScore;

  factory AiDailySuggestion.fromJson(Map<String, dynamic> json) {
    return AiDailySuggestion(
      suggestion: json['suggestion'] as String? ?? '',
      highlightTaskTitle: json['highlightTaskTitle'] as String?,
      highlightScore: (json['highlightScore'] as num?)?.toDouble(),
    );
  }
}

class AiPlanModel {
  const AiPlanModel({
    required this.generatedAt,
    required this.dailySuggestion,
    required this.sortedTasks,
    required this.drafts,
    required this.pomodoroSessions,
  });

  final DateTime generatedAt;
  final String dailySuggestion;
  final List<AiTaskScore> sortedTasks;
  final List<AiPlanDraftModel> drafts;
  final List<AiPomodoroSession> pomodoroSessions;

  factory AiPlanModel.fromJson(Map<String, dynamic> json) {
    return AiPlanModel(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      dailySuggestion: json['dailySuggestion'] as String? ?? '',
      sortedTasks: ((json['sortedTasks'] ?? []) as List)
          .map((item) => AiTaskScore.fromJson(item as Map<String, dynamic>))
          .toList(),
      drafts: ((json['drafts'] ?? []) as List)
          .map(
            (item) => AiPlanDraftModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      pomodoroSessions: ((json['pomodoroSessions'] ?? []) as List)
          .map(
            (item) => AiPomodoroSession.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
