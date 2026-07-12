class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? token;

  void saveToken(String value) {
    token = value;
  }

  void clear() {
    token = null;
  }
}
