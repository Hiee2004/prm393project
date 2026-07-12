import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/smart_schedule.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  Future<SmartSchedulePlan> generateSmartSchedule(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Schedule/smart'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Generate smart schedule failed: ${response.body}');
    }

    return SmartSchedulePlan.fromJson(jsonDecode(response.body));
  }

  Future<SmartSchedulePlan> getTodaySmartSchedule(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Schedule/today'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load smart schedule failed: ${response.body}');
    }

    return SmartSchedulePlan.fromJson(jsonDecode(response.body));
  }

  Future<SmartScheduledTask> updateScheduledTask({
    required String token,
    required int scheduledTaskId,
    required DateTime startTime,
    required DateTime endTime,
    bool allowOverlap = true,
    bool shiftConflicts = false,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Schedule/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'scheduledTaskId': scheduledTaskId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'allowOverlap': allowOverlap,
        'shiftConflicts': shiftConflicts,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Update scheduled task failed: ${response.body}');
    }

    return SmartScheduledTask.fromJson(jsonDecode(response.body));
  }

  Future<DailyScheduleSuggestion> getDailySuggestion(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Schedule/daily-suggestion'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load schedule suggestion failed: ${response.body}');
    }

    return DailyScheduleSuggestion.fromJson(jsonDecode(response.body));
  }
}
