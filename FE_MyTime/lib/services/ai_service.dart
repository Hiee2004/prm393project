import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/smart_schedule.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/models/smart_task_plan.dart';
import 'package:project/services/api_error.dart';

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
      throw buildApiException(
        response,
        fallbackMessage: 'Generate smart schedule failed.',
      );
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
      throw buildApiException(
        response,
        fallbackMessage: 'Load smart schedule failed.',
      );
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
      throw buildApiException(
        response,
        fallbackMessage: 'Update scheduled task failed.',
      );
    }

    return SmartScheduledTask.fromJson(jsonDecode(response.body));
  }

  Future<DailyScheduleSuggestion> getDailySuggestion(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Schedule/daily-suggestion'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Load schedule suggestion failed.',
      );
    }

    return DailyScheduleSuggestion.fromJson(jsonDecode(response.body));
  }

  Future<SmartTaskPlan> generateSmartTaskPlan({
    required String token,
    required String taskId,
    String mode = 'Detailed',
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/Ai/tasks/$taskId/smart-plan?mode=${Uri.encodeQueryComponent(mode)}',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Generate smart task plan failed.',
      );
    }

    return SmartTaskPlan.fromJson(jsonDecode(response.body));
  }

  Future<FocusTask> applySmartTaskPlan({
    required String token,
    required String taskId,
    required SmartTaskPlan plan,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Ai/tasks/$taskId/apply-smart-plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'suggestedFocusMinutes': plan.suggestedFocusMinutes,
        'suggestedDifficulty': plan.suggestedDifficulty,
        'breakdownTitles': plan.breakdown.map((step) => step.title).toList(),
        'recommendedFocusMode': plan.recommendedFocusMode,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Apply smart task plan failed.',
      );
    }

    return FocusTask.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
