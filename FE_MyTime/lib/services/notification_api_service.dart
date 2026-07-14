import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/app_notification.dart';
import 'package:project/services/api_error.dart';

class NotificationApiService {
  NotificationApiService._();

  static final NotificationApiService instance = NotificationApiService._();

  Future<List<AppNotification>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Load notifications failed.',
      );
    }

    final data = jsonDecode(response.body) as List;
    return data
        .map(
          (item) => AppNotification.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<AppNotification> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Mark notification as read failed.',
      );
    }

    return AppNotification.fromJson(jsonDecode(response.body));
  }

  Future<void> markAllAsRead(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Mark all notifications as read failed.',
      );
    }
  }
}
