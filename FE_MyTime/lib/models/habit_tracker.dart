class ProductivityStreakDayModel {
  const ProductivityStreakDayModel({
    required this.date,
    required this.completedTaskCount,
    required this.focusSeconds,
    required this.isProductive,
  });

  final DateTime date;
  final int completedTaskCount;
  final int focusSeconds;
  final bool isProductive;

  factory ProductivityStreakDayModel.fromJson(Map<String, dynamic> json) {
    return ProductivityStreakDayModel(
      date: DateTime.parse(json['date'] as String),
      completedTaskCount: json['completedTaskCount'] as int? ?? 0,
      focusSeconds: json['focusSeconds'] as int? ?? 0,
      isProductive: json['isProductive'] as bool? ?? false,
    );
  }
}

class ProductivityStreakDashboardModel {
  const ProductivityStreakDashboardModel({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalProductiveDays,
    required this.minimumFocusMinutes,
    required this.calendar,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalProductiveDays;
  final int minimumFocusMinutes;
  final List<ProductivityStreakDayModel> calendar;

  factory ProductivityStreakDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProductivityStreakDashboardModel(
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      totalProductiveDays: json['totalProductiveDays'] as int? ?? 0,
      minimumFocusMinutes: json['minimumFocusMinutes'] as int? ?? 25,
      calendar: ((json['calendar'] ?? []) as List)
          .map(
            (item) => ProductivityStreakDayModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
