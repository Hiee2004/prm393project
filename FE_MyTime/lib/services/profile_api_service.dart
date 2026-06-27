import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/models/user_profile.dart';

class ProfileApiService {
  ProfileApiService._();

  static final ProfileApiService instance = ProfileApiService._();

  static const String baseUrl = 'https://localhost:7063';

  Future<UserProfile> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Users/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load profile failed: ${response.body}');
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
      throw Exception('Update profile failed: ${response.body}');
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
