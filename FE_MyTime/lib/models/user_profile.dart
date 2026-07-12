class UserProfile {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String timeZone;
  final String themeMode;

  const UserProfile({
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.timeZone = 'Asia/Ho_Chi_Minh',
    this.themeMode = 'Light',
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
    String? timeZone,
    String? themeMode,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      timeZone: timeZone ?? this.timeZone,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
