import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/ai_plan.dart';

class AiApiService {
  AiApiService._();

  static final AiApiService instance = AiApiService._();

  Future<AiPlanModel> generatePlan(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Ai/generate-plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Generate AI plan failed: ${response.body}');
    }

    return AiPlanModel.fromJson(jsonDecode(response.body));
  }

  Future<List<AiTaskScore>> sortTasks(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Ai/sort-tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Sort AI tasks failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data
        .map((item) => AiTaskScore.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AiPomodoroSession>> generatePomodoro(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/Ai/pomodoro'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Generate AI pomodoro failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data
        .map((item) => AiPomodoroSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AiDailySuggestion> getDailySuggestion(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Ai/daily-suggestion'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load AI suggestion failed: ${response.body}');
    }

    return AiDailySuggestion.fromJson(jsonDecode(response.body));
  }
}
