import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/focus_task.dart';
import 'package:project/services/api_error.dart';

class FocusTaskApiService {
  FocusTaskApiService._();

  static final FocusTaskApiService instance = FocusTaskApiService._();

  Future<List<FocusTask>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/FocusTasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(response, fallbackMessage: 'Load tasks failed.');
    }

    final data = jsonDecode(response.body) as List;

    return data
        .map((item) => FocusTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FocusTask> createTask({
    required String token,
    required FocusTask task,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/FocusTasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(task.toCreateJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Create task failed.',
      );
    }

    return FocusTask.fromJson(jsonDecode(response.body));
  }

  Future<FocusTask> updateTask({
    required String token,
    required FocusTask task,
    DateTime? occurrenceDate,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/FocusTasks/${task.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(task.toUpdateJson(occurrenceDate: occurrenceDate)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Update task failed.',
      );
    }

    return FocusTask.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteTask({
    required String token,
    required String taskId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/FocusTasks/$taskId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Delete task failed.',
      );
    }
  }
}
