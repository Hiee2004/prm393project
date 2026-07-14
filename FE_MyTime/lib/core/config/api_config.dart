import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _defaultBaseUrl =
      'https://prm393project-production.up.railway.app';

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return _defaultBaseUrl;
  }
}
