class HabitModel {
  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.frequencyType,
    required this.weekDays,
    required this.targetCount,
    required this.reminderTime,
    required this.colorHex,
    required this.iconName,
    required this.isArchived,
    required this.currentStreak,
    required this.bestStreak,
    required this.completedCountToday,
    required this.completedToday,
    required this.completionRate,
  });

  final int id;
  final String title;
  final String? description;
  final String frequencyType;
  final List<int> weekDays;
  final int targetCount;
  final String? reminderTime;
  final String colorHex;
  final String iconName;
  final bool isArchived;
  final int currentStreak;
  final int bestStreak;
  final int completedCountToday;
  final bool completedToday;
  final double completionRate;

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      frequencyType: json['frequencyType'] as String? ?? 'Daily',
      weekDays: ((json['weekDays'] ?? []) as List)
          .map((item) => (item as num).toInt())
          .toList(),
      targetCount: json['targetCount'] as int? ?? 1,
      reminderTime: json['reminderTime']?.toString(),
      colorHex: json['colorHex'] as String? ?? '#58CC02',
      iconName: json['iconName'] as String? ?? 'local_fire_department_rounded',
      isArchived: json['isArchived'] as bool? ?? false,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      completedCountToday: json['completedCountToday'] as int? ?? 0,
      completedToday: json['completedToday'] as bool? ?? false,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class UserProgressModel {
  const UserProgressModel({
    required this.xp,
    required this.level,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalHabitCompletions,
    required this.nextLevelXp,
  });

  final int xp;
  final int level;
  final int currentStreak;
  final int bestStreak;
  final int totalHabitCompletions;
  final int nextLevelXp;

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      totalHabitCompletions: json['totalHabitCompletions'] as int? ?? 0,
      nextLevelXp: json['nextLevelXp'] as int? ?? 100,
    );
  }
}

class HabitHeatmapCell {
  const HabitHeatmapCell({
    required this.date,
    required this.count,
    required this.intensity,
  });

  final DateTime date;
  final int count;
  final int intensity;

  factory HabitHeatmapCell.fromJson(Map<String, dynamic> json) {
    return HabitHeatmapCell(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
      intensity: json['intensity'] as int? ?? 0,
    );
  }
}

class HabitDashboardModel {
  const HabitDashboardModel({
    required this.progress,
    required this.habits,
    required this.heatmap,
  });

  final UserProgressModel progress;
  final List<HabitModel> habits;
  final List<HabitHeatmapCell> heatmap;

  factory HabitDashboardModel.fromJson(Map<String, dynamic> json) {
    return HabitDashboardModel(
      progress: UserProgressModel.fromJson(
        (json['progress'] as Map<String, dynamic>?) ?? const {},
      ),
      habits: ((json['habits'] ?? []) as List)
          .map((item) => HabitModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      heatmap: ((json['heatmap'] ?? []) as List)
          .map((item) => HabitHeatmapCell.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
