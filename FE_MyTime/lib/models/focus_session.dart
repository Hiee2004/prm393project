class FocusSession {
  const FocusSession({
    required this.id,
    required this.focusTaskId,
    required this.taskTitle,
    required this.plannedSeconds,
    required this.actualFocusSeconds,
    required this.completedOutputs,
    required this.totalOutputs,
    required this.distractionCount,
    required this.focusScore,
    required this.startedAt,
    required this.completedAt,
  });

  final int id;
  final int focusTaskId;
  final String taskTitle;
  final int plannedSeconds;
  final int actualFocusSeconds;
  final int completedOutputs;
  final int totalOutputs;
  final int distractionCount;
  final double focusScore;
  final DateTime startedAt;
  final DateTime? completedAt;

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] ?? 0,
      focusTaskId: json['focusTaskId'] ?? 0,
      taskTitle: json['taskTitle'] ?? '',
      plannedSeconds: json['plannedSeconds'] ?? 0,
      actualFocusSeconds: json['actualFocusSeconds'] ?? 0,
      completedOutputs: json['completedOutputs'] ?? 0,
      totalOutputs: json['totalOutputs'] ?? 0,
      distractionCount: json['distractionCount'] ?? 0,
      focusScore: (json['focusScore'] ?? 0).toDouble(),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt']),
    );
  }
  int get completionPercent {
    if (totalOutputs == 0) return 0;
    return ((completedOutputs / totalOutputs) * 100).round();
  }
}
