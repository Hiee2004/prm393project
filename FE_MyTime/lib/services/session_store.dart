import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore._();

  static const _tokenPreferenceKey = 'mytime_auth_token';
  static final SessionStore instance = SessionStore._();

  String? token;

  Future<void> hydrateFromLocal() async {
    final preferences = await SharedPreferences.getInstance();
    token = preferences.getString(_tokenPreferenceKey);
  }

  void saveToken(String value) {
    token = value;
    unawaited(_persistToken(value));
  }

  void clear() {
    token = null;
    unawaited(_clearPersistedToken());
  }

  Future<void> _persistToken(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenPreferenceKey, value);
  }

  Future<void> _clearPersistedToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenPreferenceKey);
  }
}
