import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/user_setting.dart';

class SettingsApiService {
  SettingsApiService._();

  static final SettingsApiService instance = SettingsApiService._();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<UserSetting> getSettings(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Users/me/settings'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load settings failed: ${response.body}');
    }

    return UserSetting.fromJson(jsonDecode(response.body));
  }

  Future<UserSetting> updateSettings({
    required String token,
    required UserSetting setting,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Users/me/settings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(setting.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Update settings failed: ${response.body}');
    }

    return UserSetting.fromJson(jsonDecode(response.body));
  }
}
