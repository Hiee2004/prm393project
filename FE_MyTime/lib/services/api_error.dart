import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

ApiException buildApiException(
  http.Response response, {
  required String fallbackMessage,
}) {
  final body = response.body.trim();
  if (body.isEmpty) {
    return ApiException(fallbackMessage);
  }

  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return ApiException(message);
      }

      final errors = decoded['errors'];
      if (errors is Map<String, dynamic>) {
        final messages = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            for (final item in value) {
              final text = item.toString().trim();
              if (text.isNotEmpty) {
                messages.add(text);
              }
            }
          }
        }
        if (messages.isNotEmpty) {
          return ApiException(messages.join('\n'));
        }
      }
    }
  } catch (_) {
    // Fall back to a plain-text message when the API body is not JSON.
  }

  return ApiException(body);
}
