import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/focus_session.dart';

class FocusSessionApiService {
  FocusSessionApiService._();

  static final FocusSessionApiService instance = FocusSessionApiService._();

  Future<void> createSession({
    required String token,
    required String focusTaskId,
    required int plannedSeconds,
    required int actualFocusSeconds,
    required int completedOutputs,
    required int totalOutputs,
    required int distractionCount,
    required int totalDistractionSeconds,
    required DateTime startedAt,
    required DateTime completedAt,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/FocusSessions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'focusTaskId': int.parse(focusTaskId),
        'plannedSeconds': plannedSeconds,
        'actualFocusSeconds': actualFocusSeconds,
        'completedOutputs': completedOutputs,
        'totalOutputs': totalOutputs,
        'distractionCount': distractionCount,
        'totalDistractionSeconds': totalDistractionSeconds,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'completedAt': completedAt.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Create focus session failed: ${response.body}');
    }
  }

  Future<List<FocusSession>> getSessions(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/FocusSessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Load focus sessions failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;

    return data
        .map((item) => FocusSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
