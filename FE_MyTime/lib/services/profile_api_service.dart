import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/user_profile.dart';
import 'package:project/services/api_error.dart';

class ProfileApiService {
  ProfileApiService._();

  static final ProfileApiService instance = ProfileApiService._();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<UserProfile> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Load profile failed.',
      );
    }

    final data = jsonDecode(response.body);

    return UserProfile(
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      timeZone: data['setting']?['timeZone'] ?? 'Asia/Ho_Chi_Minh',
      themeMode: data['setting']?['themeMode'] ?? 'Light',
    );
  }

  Future<UserProfile> updateProfile({
    required String token,
    required String fullName,
    required String email,
    String? avatarUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Users/me/profile'),
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Update profile failed.',
      );
    }

    final data = jsonDecode(response.body);

    return UserProfile(
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      timeZone: data['setting']?['timeZone'] ?? 'Asia/Ho_Chi_Minh',
      themeMode: data['setting']?['themeMode'] ?? 'Light',
    );
  }
}
