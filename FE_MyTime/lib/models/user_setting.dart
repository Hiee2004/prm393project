class UserSetting {
  final int defaultFocusMinutes;
  final bool notificationEnabled;
  final bool autoSyncGoogleCalendar;
  final bool dailyReviewEnabled;
  final String? dailyReviewTime;
  final String? preferredFocusStartTime;
  final String? preferredFocusEndTime;
  final String timeZone;
  final String themeMode;
  final String? energyProfileJson;

  const UserSetting({
    required this.defaultFocusMinutes,
    required this.notificationEnabled,
    required this.autoSyncGoogleCalendar,
    required this.dailyReviewEnabled,
    this.dailyReviewTime,
    this.preferredFocusStartTime,
    this.preferredFocusEndTime,
    required this.timeZone,
    required this.themeMode,
    this.energyProfileJson,
  });

  factory UserSetting.fromJson(Map<String, dynamic> json) {
    return UserSetting(
      defaultFocusMinutes: json['defaultFocusMinutes'] ?? 25,
      notificationEnabled: json['notificationEnabled'] ?? true,
      autoSyncGoogleCalendar: json['autoSyncGoogleCalendar'] ?? false,
      dailyReviewEnabled: json['dailyReviewEnabled'] ?? true,
      dailyReviewTime: json['dailyReviewTime'],
      preferredFocusStartTime: json['preferredFocusStartTime'],
      preferredFocusEndTime: json['preferredFocusEndTime'],
      timeZone: json['timeZone'] ?? 'Asia/Ho_Chi_Minh',
      themeMode: json['themeMode'] ?? 'Light',
      energyProfileJson: json['energyProfileJson'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultFocusMinutes': defaultFocusMinutes,
      'notificationEnabled': notificationEnabled,
      'autoSyncGoogleCalendar': autoSyncGoogleCalendar,
      'dailyReviewEnabled': dailyReviewEnabled,
      'dailyReviewTime': dailyReviewTime,
      'preferredFocusStartTime': preferredFocusStartTime,
      'preferredFocusEndTime': preferredFocusEndTime,
      'timeZone': timeZone,
      'themeMode': themeMode,
      'energyProfileJson': energyProfileJson,
    };
  }

  UserSetting copyWith({
    int? defaultFocusMinutes,
    bool? notificationEnabled,
    bool? autoSyncGoogleCalendar,
    bool? dailyReviewEnabled,
    String? dailyReviewTime,
    String? preferredFocusStartTime,
    String? preferredFocusEndTime,
    String? timeZone,
    String? themeMode,
    String? energyProfileJson,
  }) {
    return UserSetting(
      defaultFocusMinutes: defaultFocusMinutes ?? this.defaultFocusMinutes,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      autoSyncGoogleCalendar:
          autoSyncGoogleCalendar ?? this.autoSyncGoogleCalendar,
      dailyReviewEnabled: dailyReviewEnabled ?? this.dailyReviewEnabled,
      dailyReviewTime: dailyReviewTime ?? this.dailyReviewTime,
      preferredFocusStartTime:
          preferredFocusStartTime ?? this.preferredFocusStartTime,
      preferredFocusEndTime:
          preferredFocusEndTime ?? this.preferredFocusEndTime,
      timeZone: timeZone ?? this.timeZone,
      themeMode: themeMode ?? this.themeMode,
      energyProfileJson: energyProfileJson ?? this.energyProfileJson,
    );
  }
}
