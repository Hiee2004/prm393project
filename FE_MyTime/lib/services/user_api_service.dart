import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/services/api_error.dart';

class UserApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    required String email,
    String? avatarUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'avatarUrl': avatarUrl,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getSettings(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/me/settings'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateSettings({
    required String token,
    required int defaultFocusMinutes,
    required bool notificationEnabled,
    required bool autoSyncGoogleCalendar,
    required bool dailyReviewEnabled,
    required String timeZone,
    required String themeMode,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/me/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'defaultFocusMinutes': defaultFocusMinutes,
        'notificationEnabled': notificationEnabled,
        'autoSyncGoogleCalendar': autoSyncGoogleCalendar,
        'dailyReviewEnabled': dailyReviewEnabled,
        'timeZone': timeZone,
        'themeMode': themeMode,
      }),
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw buildApiException(
      response,
      fallbackMessage: body['message']?.toString() ?? 'API error',
    );
  }
}
