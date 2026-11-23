import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String apiErrorMessage(http.Response response, String fallback) {
  try {
    final Object? decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      for (final key in const <String>['detail', 'message', 'error']) {
        final Object? value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
  } catch (_) {
    // Fall through to the generic message for non-JSON responses.
  }
  return fallback;
}
