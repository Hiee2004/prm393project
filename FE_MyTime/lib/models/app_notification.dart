class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.focusTaskId,
    this.scheduledAt,
    this.sentAt,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int? focusTaskId;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'System',
      isRead: json['isRead'] as bool? ?? false,
      focusTaskId: json['focusTaskId'] as int?,
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}
