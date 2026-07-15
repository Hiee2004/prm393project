class SmartTaskPlan {
  const SmartTaskPlan({
    required this.taskId,
    required this.taskTitle,
    required this.planMode,
    required this.suggestedDifficulty,
    required this.suggestedFocusMinutes,
    required this.recommendedFocusMode,
    required this.bestTimeOfDay,
    required this.recommendation,
    required this.breakdown,
    required this.pomodoroPlan,
    required this.generatedAt,
  });

  final int taskId;
  final String taskTitle;
  final String planMode;
  final int suggestedDifficulty;
  final int suggestedFocusMinutes;
  final String recommendedFocusMode;
  final String bestTimeOfDay;
  final String recommendation;
  final List<SmartTaskStep> breakdown;
  final List<SmartTaskPomodoroItem> pomodoroPlan;
  final DateTime generatedAt;

  factory SmartTaskPlan.fromJson(Map<String, dynamic> json) {
    return SmartTaskPlan(
      taskId: json['taskId'] as int? ?? 0,
      taskTitle: json['taskTitle'] as String? ?? '',
      planMode: json['planMode'] as String? ?? 'Detailed',
      suggestedDifficulty: json['suggestedDifficulty'] as int? ?? 3,
      suggestedFocusMinutes: json['suggestedFocusMinutes'] as int? ?? 25,
      recommendedFocusMode:
          json['recommendedFocusMode'] as String? ?? 'Balanced Focus 45/10',
      bestTimeOfDay: json['bestTimeOfDay'] as String? ?? 'Morning',
      recommendation: json['recommendation'] as String? ?? '',
      breakdown: ((json['breakdown'] ?? []) as List)
          .map((item) => SmartTaskStep.fromJson(item as Map<String, dynamic>))
          .toList(),
      pomodoroPlan: ((json['pomodoroPlan'] ?? []) as List)
          .map(
            (item) =>
                SmartTaskPomodoroItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      generatedAt: DateTime.parse(
        json['generatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'planMode': planMode,
      'suggestedDifficulty': suggestedDifficulty,
      'suggestedFocusMinutes': suggestedFocusMinutes,
      'recommendedFocusMode': recommendedFocusMode,
      'bestTimeOfDay': bestTimeOfDay,
      'recommendation': recommendation,
      'breakdown': breakdown.map((item) => item.toJson()).toList(),
      'pomodoroPlan': pomodoroPlan.map((item) => item.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class SmartTaskStep {
  const SmartTaskStep({
    required this.order,
    required this.title,
    required this.minutes,
  });

  final int order;
  final String title;
  final int minutes;

  factory SmartTaskStep.fromJson(Map<String, dynamic> json) {
    return SmartTaskStep(
      order: json['order'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'title': title,
      'minutes': minutes,
    };
  }
}

class SmartTaskPomodoroItem {
  const SmartTaskPomodoroItem({
    required this.label,
    required this.minutes,
    required this.isBreak,
  });

  final String label;
  final int minutes;
  final bool isBreak;

  factory SmartTaskPomodoroItem.fromJson(Map<String, dynamic> json) {
    return SmartTaskPomodoroItem(
      label: json['label'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 0,
      isBreak: json['isBreak'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'minutes': minutes,
      'isBreak': isBreak,
    };
  }
}
