import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/habit_tracker.dart';

class HabitApiService {
  HabitApiService._();

  static final HabitApiService instance = HabitApiService._();

  Future<HabitDashboardModel> getDashboard(
    String token, {
    int days = 84,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Habits/dashboard?days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load habits failed: ${response.body}');
    }

    return HabitDashboardModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<HabitModel> createHabit({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Habits'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Create habit failed: ${response.body}');
    }

    return HabitModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<HabitModel> checkInHabit({
    required String token,
    required int habitId,
    int incrementBy = 1,
    DateTime? completedOn,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Habits/$habitId/check-in'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'incrementBy': incrementBy,
        if (completedOn != null) 'completedOn': completedOn.toIso8601String(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Check-in failed: ${response.body}');
    }

    return HabitModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
