import 'package:shared_preferences/shared_preferences.dart';

class StreakFreezeStore {
  StreakFreezeStore._();

  static const _baseKey = 'mytime_streak_freeze_dates';
  static final StreakFreezeStore instance = StreakFreezeStore._();

  String _keyForUser(String? token) {
    final safeToken = token == null || token.isEmpty ? 'guest' : token;
    return '$_baseKey::$safeToken';
  }

  Future<List<DateTime>> getUsedDates(String? token) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_keyForUser(token)) ?? const [];
    return raw
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList();
  }

  Future<void> saveUsedDates(String? token, List<DateTime> dates) async {
    final preferences = await SharedPreferences.getInstance();
    final normalized = dates
        .map((date) => DateTime(date.year, date.month, date.day).toIso8601String())
        .toList();
    await preferences.setStringList(_keyForUser(token), normalized);
  }
}
