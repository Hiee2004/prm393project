import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project/core/config/api_config.dart';
import 'package:project/models/habit_tracker.dart';
import 'package:project/services/api_error.dart';

class HabitApiService {
  HabitApiService._();

  static final HabitApiService instance = HabitApiService._();

  Future<ProductivityStreakDashboardModel> getDashboard(
    String token, {
    int days = 180,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/ProductivityStreak/dashboard?days=$days',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw buildApiException(
        response,
        fallbackMessage: 'Load productivity streak failed.',
      );
    }

    return ProductivityStreakDashboardModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
