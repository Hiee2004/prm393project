import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FocusTimerDraftStore {
  FocusTimerDraftStore._();

  static const _draftKey = 'mytime_focus_timer_draft';
  static final FocusTimerDraftStore instance = FocusTimerDraftStore._();

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_draftKey, jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> getDraft() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_draftKey);
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftKey);
  }
}
